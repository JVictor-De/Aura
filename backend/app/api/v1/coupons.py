"""
Rotas de cupons.

Referências:
- ARCHITECTURE.md §2.2: Cupons e Promos (Promotion Engine)
- ARCHITECTURE.md §7: api/v1/coupons.py
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime

from app.database import get_db
from app.core.security import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.coupon import Coupon
from app.services.promotion_service import PromotionService

router = APIRouter()


class CreateCouponRequest(BaseModel):
    code: str = Field(min_length=3, max_length=50)
    discount_value: float = Field(gt=0)
    discount_type: str = "percentage"
    min_purchase: float = 0
    max_uses: int = 0
    max_uses_per_user: int = 1
    valid_from: datetime
    valid_until: datetime


class CouponResponse(BaseModel):
    id: UUID
    code: str
    discount_value: float
    discount_type: str
    min_purchase: float
    max_uses: int
    current_uses: int
    is_active: bool
    valid_from: datetime
    valid_until: datetime

    model_config = {"from_attributes": True}


class ValidateCouponRequest(BaseModel):
    code: str
    store_id: UUID | None = None
    subtotal: float = Field(gt=0)


@router.post("/", response_model=CouponResponse, status_code=201)
async def create_coupon(
    data: CreateCouponRequest,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Cria um cupom para a loja do lojista autenticado."""
    coupon = Coupon(
        store_id=current_user.store_id,
        code=data.code.upper().strip(),
        discount_value=data.discount_value,
        discount_type=data.discount_type,
        min_purchase=data.min_purchase,
        max_uses=data.max_uses,
        max_uses_per_user=data.max_uses_per_user,
        valid_from=data.valid_from,
        valid_until=data.valid_until,
    )
    db.add(coupon)
    await db.flush()
    return coupon


@router.get("/", response_model=list[CouponResponse])
async def list_coupons(
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Lista cupons da loja do lojista autenticado."""
    stmt = select(Coupon)
    if current_user.role == UserRole.MERCHANT and current_user.store_id:
        stmt = stmt.where(Coupon.store_id == current_user.store_id)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.post("/validate")
async def validate_coupon(
    data: ValidateCouponRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Valida cupom antes do checkout.
    ARCHITECTURE.md §2.2: cálculo backend-driven.
    """
    service = PromotionService(db)
    result = await service.validate_coupon(
        code=data.code,
        user_id=current_user.id,
        store_id=data.store_id,
        subtotal=data.subtotal,
    )
    return result


@router.patch("/{coupon_id}/deactivate")
async def deactivate_coupon(
    coupon_id: UUID,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Desativa cupom."""
    coupon = await db.get(Coupon, coupon_id)
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    if current_user.role == UserRole.MERCHANT and coupon.store_id != current_user.store_id:
        raise HTTPException(status_code=403, detail="Not your coupon")
    coupon.is_active = False
    return {"detail": "Coupon deactivated"}
