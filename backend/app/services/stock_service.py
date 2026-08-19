"""
Stock Reservation Service com controle de race conditions.

Referências:
- TECHNICAL_AUDIT.md §1.2 Sincronização de Estoque:
  - SELECT FOR UPDATE (nowait) para evitar overselling
  - Distributed lock no Redis (Redlock)
  - Reserva temporária com TTL 15min
  - Confirmação converte reserva em baixa definitiva
- ARCHITECTURE.md §ERD: STOCK_RESERVATIONS com reserved_until e status
- ARCHITECTURE.md §Checkout Crítico §2: cria STOCK_RESERVATIONS por SKU com TTL
"""

import json
import uuid
from datetime import datetime, timedelta

import redis.asyncio as aioredis
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import OperationalError

from app.models.product import SkuVariant
from app.models.stock_reservation import StockReservation, ReservationStatus
from app.config import get_settings
from app.core.middleware.exception_handler import StockLockError, ReservationExpiredError

settings = get_settings()


class StockReservationService:
    """
    Implementa o fluxo de reserva descrito no TECHNICAL_AUDIT.md §1.2:
    1. Lock distribuído no Redis
    2. Verifica estoque real no PostgreSQL (SELECT FOR UPDATE)
    3. Cria reserva temporária (Redis TTL + registro PostgreSQL)
    4. Decrementa estoque disponível na confirmação
    """

    RESERVATION_TTL = settings.STOCK_RESERVATION_TTL_SECONDS  # 15 min

    def __init__(self, db: AsyncSession, redis: aioredis.Redis):
        self.db = db
        self.redis = redis

    async def reserve_stock(
        self,
        sku: str,
        quantity: int,
        user_id: str,
        session_id: str,
    ) -> dict:
        """
        Reserva temporária de estoque.
        Retorna dict com reservation_id e expires_at ou levanta StockLockError.
        """
        lock_key = f"stock_lock:{sku}"
        reservation_key = f"reservation:{session_id}:{sku}"

        # Distributed lock com timeout (TECHNICAL_AUDIT §1.2)
        lock = self.redis.lock(lock_key, timeout=5)
        acquired = await lock.acquire(blocking_timeout=3)
        if not acquired:
            raise StockLockError(sku=sku, available=0)

        try:
            # SELECT FOR UPDATE nowait (TECHNICAL_AUDIT §1.2 – evita overselling)
            stmt = (
                select(SkuVariant)
                .where(SkuVariant.sku == sku)
                .with_for_update(nowait=True)
            )

            try:
                result = await self.db.execute(stmt)
                variant = result.scalar_one_or_none()
            except OperationalError:
                raise StockLockError(sku=sku, available=0)

            if not variant:
                raise StockLockError(sku=sku, available=0)

            # Calcular estoque disponível (real - reservado)
            reserved_count = await self._get_reserved_count(sku)
            available = variant.stock_quantity - reserved_count

            if available < quantity:
                raise StockLockError(sku=sku, available=available)

            # Criar reserva no Redis com TTL
            now = datetime.utcnow()
            expires_at = now + timedelta(seconds=self.RESERVATION_TTL)

            reservation_data = {
                "sku": sku,
                "sku_variant_id": str(variant.id),
                "quantity": quantity,
                "user_id": user_id,
                "created_at": now.isoformat(),
                "expires_at": expires_at.isoformat(),
            }

            await self.redis.setex(
                reservation_key,
                self.RESERVATION_TTL,
                json.dumps(reservation_data),
            )
            await self.redis.sadd(f"sku_reservations:{sku}", reservation_key)

            # Registro permanente no PostgreSQL
            db_reservation = StockReservation(
                sku_variant_id=variant.id,
                user_id=uuid.UUID(user_id),
                quantity=quantity,
                status=ReservationStatus.ACTIVE,
                reserved_until=expires_at,
            )
            self.db.add(db_reservation)

            # Atualizar stock_lock_timestamp (ARCHITECTURE.md §Notas de Modelagem)
            variant.stock_lock_timestamp = now

            await self.db.flush()

            return {
                "reservation_id": reservation_key,
                "db_reservation_id": str(db_reservation.id),
                "expires_at": expires_at.isoformat(),
            }
        finally:
            await lock.release()

    async def confirm_reservation(self, reservation_id: str) -> bool:
        """
        Confirma a reserva e decrementa o estoque real.
        ARCHITECTURE.md §Checkout Crítico §6: converte reserva em baixa definitiva.
        """
        reservation_data = await self.redis.get(reservation_id)
        if not reservation_data:
            raise ReservationExpiredError(reservation_id=reservation_id)

        data = json.loads(reservation_data)

        # Decrementar estoque real com optimistic lock
        stmt = (
            update(SkuVariant)
            .where(
                SkuVariant.sku == data["sku"],
                SkuVariant.stock_quantity >= data["quantity"],
            )
            .values(stock_quantity=SkuVariant.stock_quantity - data["quantity"])
        )

        result = await self.db.execute(stmt)
        if result.rowcount == 0:
            return False

        # Atualizar reserva no PostgreSQL
        if "sku_variant_id" in data:
            db_stmt = (
                update(StockReservation)
                .where(
                    StockReservation.sku_variant_id == uuid.UUID(data["sku_variant_id"]),
                    StockReservation.status == ReservationStatus.ACTIVE,
                )
                .values(status=ReservationStatus.CONFIRMED)
            )
            await self.db.execute(db_stmt)

        # Limpar reserva do Redis
        await self._clear_reservation(reservation_id, data["sku"])
        return True

    async def release_reservation(self, reservation_id: str):
        """
        Libera reserva manualmente (falha de pagamento ou cancelamento).
        TECHNICAL_AUDIT §1.2: "falhas em transações de pagamento sempre revertam o lock"
        """
        reservation_data = await self.redis.get(reservation_id)
        if reservation_data:
            data = json.loads(reservation_data)
            await self._clear_reservation(reservation_id, data["sku"])

            # Marcar como cancelada no PostgreSQL
            if "sku_variant_id" in data:
                db_stmt = (
                    update(StockReservation)
                    .where(
                        StockReservation.sku_variant_id == uuid.UUID(data["sku_variant_id"]),
                        StockReservation.status == ReservationStatus.ACTIVE,
                    )
                    .values(status=ReservationStatus.CANCELLED)
                )
                await self.db.execute(db_stmt)

    async def _get_reserved_count(self, sku: str) -> int:
        """Soma todas as reservas ativas para um SKU (TECHNICAL_AUDIT §1.2)."""
        reservation_keys = await self.redis.smembers(f"sku_reservations:{sku}")
        total = 0
        for key in reservation_keys:
            data = await self.redis.get(key)
            if data:
                total += json.loads(data)["quantity"]
            else:
                await self.redis.srem(f"sku_reservations:{sku}", key)
        return total

    async def _clear_reservation(self, reservation_id: str, sku: str):
        await self.redis.delete(reservation_id)
        await self.redis.srem(f"sku_reservations:{sku}", reservation_id)
