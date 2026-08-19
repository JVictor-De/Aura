"""
RMA Service: logística reversa e estorno parcial.

Referências:
- ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
- ARCHITECTURE.md §ERD: RMA_REQUESTS, RMA_ITEMS
- TECHNICAL_AUDIT.md: estorno parcial via PaymentService
"""

import logging
from uuid import UUID
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.rma import RmaRequest, RmaItem, RmaStatus
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import SkuVariant

logger = logging.getLogger("zoe.rma_service")

# Prazo máximo para solicitar devolução (dias)
RMA_DEADLINE_DAYS = 7


class RmaService:
    """
    Serviço de devoluções e trocas.

    ARCHITECTURE.md §2.4: "A tela de pedidos permite, em até 7 dias,
    um flow de um clique para Solicitar Devolução por item individual."
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def can_request_rma(self, order_id: UUID, user_id: UUID) -> dict:
        """Verifica se o pedido é elegível para devolução."""
        result = await self.db.execute(
            select(Order).where(Order.id == order_id, Order.user_id == user_id)
        )
        order = result.scalar_one_or_none()

        if not order:
            return {"eligible": False, "reason": "Pedido não encontrado."}

        if order.status != OrderStatus.DELIVERED:
            return {"eligible": False, "reason": "Pedido ainda não foi entregue."}

        deadline = order.created_at + timedelta(days=RMA_DEADLINE_DAYS)
        if datetime.utcnow() > deadline:
            return {
                "eligible": False,
                "reason": f"Prazo de {RMA_DEADLINE_DAYS} dias para devolução expirou.",
            }

        # Verificar se já existe RMA ativo
        existing = await self.db.execute(
            select(RmaRequest).where(
                RmaRequest.order_id == order_id,
                RmaRequest.status.in_([RmaStatus.REQUESTED, RmaStatus.APPROVED]),
            )
        )
        if existing.scalar_one_or_none():
            return {
                "eligible": False,
                "reason": "Já existe uma solicitação de devolução em andamento.",
            }

        return {"eligible": True}

    async def create_rma_request(
        self,
        order_id: UUID,
        user_id: UUID,
        items: list[dict],
        reason: str,
    ) -> RmaRequest:
        """
        Cria solicitação de devolução por item.

        items: [{"order_item_id": "...", "quantity": 1, "reason": "wrong_size"}]
        """
        eligibility = await self.can_request_rma(order_id, user_id)
        if not eligibility["eligible"]:
            raise ValueError(eligibility["reason"])

        rma = RmaRequest(
            order_id=order_id,
            reason=reason,
            status=RmaStatus.REQUESTED,
        )
        self.db.add(rma)
        await self.db.flush()

        for item_data in items:
            rma_item = RmaItem(
                rma_request_id=rma.id,
                order_item_id=UUID(item_data["order_item_id"]),
                quantity=item_data["quantity"],
                resolution=item_data.get("reason", "changed_mind"),
            )
            self.db.add(rma_item)

        await self.db.flush()
        return rma

    async def approve_rma(self, rma_id: UUID) -> RmaRequest:
        """
        Aprova devolução e prepara para restock.
        Chamado pelo lojista no portal.
        """
        rma = await self.db.get(RmaRequest, rma_id)
        if not rma:
            raise ValueError("RMA não encontrada.")

        if rma.status != RmaStatus.REQUESTED:
            raise ValueError(f"RMA em status {rma.status.value} não pode ser aprovada.")

        rma.status = RmaStatus.APPROVED
        await self.db.flush()

        logger.info("RMA %s approved for order %s", rma_id, rma.order_id)
        return rma

    async def reject_rma(self, rma_id: UUID, reason: str = "") -> RmaRequest:
        """Rejeita devolução."""
        rma = await self.db.get(RmaRequest, rma_id)
        if not rma:
            raise ValueError("RMA não encontrada.")

        rma.status = RmaStatus.REJECTED
        await self.db.flush()
        return rma

    async def complete_rma(self, rma_id: UUID) -> RmaRequest:
        """
        Conclui a devolução: devolve estoque dos itens.
        Chamado quando o produto é recebido de volta.
        """
        rma = await self.db.get(RmaRequest, rma_id)
        if not rma or rma.status != RmaStatus.APPROVED:
            raise ValueError("RMA não encontrada ou não aprovada.")

        # Restock
        for rma_item in rma.items:
            order_item = await self.db.get(OrderItem, rma_item.order_item_id)
            if order_item:
                await self.db.execute(
                    update(SkuVariant)
                    .where(SkuVariant.id == order_item.sku_variant_id)
                    .values(
                        stock_quantity=SkuVariant.stock_quantity + rma_item.quantity
                    )
                )

        rma.status = RmaStatus.RESOLVED
        await self.db.flush()

        logger.info("RMA %s resolved — stock restored", rma_id)
        return rma
