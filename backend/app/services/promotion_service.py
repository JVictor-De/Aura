"""
Promotion Service: cálculo e validação de cupons.

Referências:
- ARCHITECTURE.md §2.2: Cupons e Promos (Promotion Engine)
- ARCHITECTURE.md §ERD: COUPONS, APPLIED_COUPONS
- TECHNICAL_AUDIT.md: preço final backend-driven (nunca frontend)
"""

import logging
from datetime import datetime
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.coupon import Coupon, AppliedCoupon, DiscountType

logger = logging.getLogger("zoe.promotion_service")


class PromotionService:
    """
    Valida e aplica cupons de desconto.

    ARCHITECTURE.md §2.2: "Cálculo do carrinho é Backend-Driven.
    O frontend confia na resposta da API para evitar fraudes client-side."
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def validate_coupon(
        self,
        code: str,
        user_id: UUID,
        store_id: UUID | None,
        subtotal: float,
    ) -> dict:
        """
        Valida se o cupom é aplicável ao pedido.

        Regras:
        1. Cupom existe e está ativo
        2. Dentro do período de validade
        3. Não atingiu max_uses global
        4. Não atingiu max_uses_per_user para este usuário
        5. Subtotal >= min_purchase
        6. Se cupom é de loja específica, store_id deve bater
        """
        result = await self.db.execute(
            select(Coupon).where(Coupon.code == code.upper().strip())
        )
        coupon = result.scalar_one_or_none()

        if not coupon or not coupon.is_active:
            return {"valid": False, "reason": "Cupom não encontrado ou inativo."}

        now = datetime.utcnow()
        if now < coupon.valid_from or now > coupon.valid_until:
            return {"valid": False, "reason": "Cupom fora do período de validade."}

        if coupon.max_uses > 0 and coupon.current_uses >= coupon.max_uses:
            return {"valid": False, "reason": "Cupom esgotado (limite de uso atingido)."}

        # Verificar uso por usuário
        user_usage = await self.db.execute(
            select(func.count(AppliedCoupon.id)).where(
                AppliedCoupon.coupon_id == coupon.id,
                AppliedCoupon.user_id == user_id,
            )
        )
        user_count = user_usage.scalar() or 0
        if user_count >= coupon.max_uses_per_user:
            return {"valid": False, "reason": "Você já usou este cupom o número máximo de vezes."}

        if subtotal < float(coupon.min_purchase):
            return {
                "valid": False,
                "reason": f"Compra mínima de R$ {float(coupon.min_purchase):.2f} não atingida.",
            }

        # Verificar escopo de loja
        if coupon.store_id and store_id and coupon.store_id != store_id:
            return {"valid": False, "reason": "Cupom não válido para esta loja."}

        # Calcular desconto
        discount = self._calculate_discount(coupon, subtotal)

        return {
            "valid": True,
            "coupon_id": str(coupon.id),
            "discount_value": discount,
            "discount_type": coupon.discount_type.value,
            "new_total": max(subtotal - discount, 0),
        }

    async def apply_coupon(
        self,
        coupon_id: UUID,
        order_id: UUID,
        user_id: UUID,
        subtotal: float,
    ) -> float:
        """
        Aplica o cupom ao pedido e retorna o valor do desconto.
        Chamado durante o checkout após validação.
        """
        coupon = await self.db.get(Coupon, coupon_id)
        if not coupon:
            return 0.0

        discount = self._calculate_discount(coupon, subtotal)

        applied = AppliedCoupon(
            order_id=order_id,
            coupon_id=coupon_id,
            user_id=user_id,
            discount_applied=discount,
        )
        self.db.add(applied)

        # Incrementar counter de uso
        coupon.current_uses += 1
        await self.db.flush()

        return discount

    @staticmethod
    def _calculate_discount(coupon: Coupon, subtotal: float) -> float:
        """Calcula valor do desconto baseado no tipo."""
        if coupon.discount_type == DiscountType.FIXED:
            return min(float(coupon.discount_value), subtotal)
        elif coupon.discount_type == DiscountType.PERCENTAGE:
            return round(subtotal * float(coupon.discount_value) / 100, 2)
        return 0.0
