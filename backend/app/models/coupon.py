"""
Model: COUPONS e APPLIED_COUPONS

Referências:
- ARCHITECTURE.md §ERD: COUPONS, APPLIED_COUPONS
- ARCHITECTURE.md §2.2: Cupons e Promos (Promotion Engine)
- TECHNICAL_AUDIT.md: preço final backend-driven
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    String, DateTime, Integer, Float, Boolean,
    ForeignKey, Enum as SAEnum, Numeric,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class DiscountType(str, enum.Enum):
    FIXED = "fixed"
    PERCENTAGE = "percentage"


class Coupon(Base):
    __tablename__ = "coupons"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    store_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stores.id"), nullable=True, index=True
    )
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    discount_value: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    discount_type: Mapped[DiscountType] = mapped_column(
        SAEnum(DiscountType), nullable=False
    )
    min_purchase: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    max_uses: Mapped[int] = mapped_column(Integer, default=0)
    current_uses: Mapped[int] = mapped_column(Integer, default=0)
    max_uses_per_user: Mapped[int] = mapped_column(Integer, default=1)
    valid_from: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    valid_until: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Relationships
    store = relationship("Store")
    applied = relationship("AppliedCoupon", back_populates="coupon", lazy="selectin")


class AppliedCoupon(Base):
    __tablename__ = "applied_coupons"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False, index=True
    )
    coupon_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("coupons.id"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    discount_applied: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    applied_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Relationships
    coupon = relationship("Coupon", back_populates="applied")
    order = relationship("Order")
    user = relationship("User")
