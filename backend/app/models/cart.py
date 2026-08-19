"""
Models: CART_SESSIONS e CART_ITEMS

Referências:
- ARCHITECTURE.md §ERD: CART_SESSIONS, CART_ITEMS
- ARCHITECTURE.md §8.2: Single-store lock no MVP
- TECHNICAL_AUDIT.md §2.4: Carrinho single-store com confirmação ao trocar
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    String, DateTime, Integer, Float, ForeignKey,
    Enum as SAEnum, Numeric,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class CartSessionStatus(str, enum.Enum):
    ACTIVE = "active"
    CHECKED_OUT = "checked_out"
    ABANDONED = "abandoned"


class CartSession(Base):
    """
    CART_SESSIONS: sessão de carrinho single-store.
    ARCHITECTURE.md §8.2: travado por 1 único store_id no MVP.
    """
    __tablename__ = "cart_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    store_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stores.id"), nullable=False, index=True
    )
    status: Mapped[CartSessionStatus] = mapped_column(
        SAEnum(CartSessionStatus), default=CartSessionStatus.ACTIVE
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), onupdate=datetime.utcnow
    )

    # Relationships
    user = relationship("User", backref="cart_sessions")
    store = relationship("Store")
    items = relationship("CartItem", back_populates="cart_session", lazy="selectin")


class CartItem(Base):
    """
    CART_ITEMS: item no carrinho com snapshot de preço.
    ARCHITECTURE.md §ERD: unit_price é snapshot no momento do add.
    """
    __tablename__ = "cart_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    cart_session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("cart_sessions.id"), nullable=False, index=True
    )
    sku_variant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sku_variants.id"), nullable=False
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    unit_price: Mapped[float] = mapped_column(
        Numeric(10, 2), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Relationships
    cart_session = relationship("CartSession", back_populates="items")
    sku_variant = relationship("SkuVariant")
