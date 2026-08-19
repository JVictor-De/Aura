"""
Models: PRODUCTS e SKU_VARIANTS

Referências:
- ARCHITECTURE.md §ERD: PRODUCTS, SKU_VARIANTS com stock_lock_timestamp
- ARCHITECTURE.md §Product Entity: id, storeId, name, brand, variants, isActive
- ARCHITECTURE.md §Notas de Modelagem: stock_lock_timestamp marca início do lock de reserva
- TECHNICAL_AUDIT.md §1.2: SELECT FOR UPDATE em SkuVariant para evitar overselling
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    String, DateTime, Float, Integer, Boolean, Text,
    ForeignKey, Enum as SAEnum,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class ProductCategory(str, enum.Enum):
    SHIRTS = "shirts"
    PANTS = "pants"
    DRESSES = "dresses"
    SHOES = "shoes"
    ACCESSORIES = "accessories"
    OUTERWEAR = "outerwear"
    UNDERWEAR = "underwear"
    SPORTSWEAR = "sportswear"


class Product(Base):
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    store_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stores.id"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=True)
    brand: Mapped[str] = mapped_column(String(100), nullable=False)
    category: Mapped[ProductCategory] = mapped_column(SAEnum(ProductCategory), nullable=False)
    base_price: Mapped[float] = mapped_column(Float, nullable=False)
    discount_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    material: Mapped[str | None] = mapped_column(String(100), nullable=True)
    fit: Mapped[str | None] = mapped_column(String(50), nullable=True)  # Regular, Slim, Oversized
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), onupdate=datetime.utcnow)

    # Relationships
    store = relationship("Store", back_populates="products")
    variants = relationship("SkuVariant", back_populates="product", lazy="selectin")


class SkuVariant(Base):
    """
    SKU_VARIANTS: cada combinação cor/tamanho de um produto.
    stock_lock_timestamp: marca início da reserva temporária (ARCHITECTURE.md §Notas de Modelagem).
    """
    __tablename__ = "sku_variants"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=False, index=True
    )
    sku: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    size: Mapped[str] = mapped_column(String(10), nullable=False)
    color: Mapped[str] = mapped_column(String(50), nullable=False)
    color_hex: Mapped[str] = mapped_column(String(7), nullable=False)
    stock_quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)

    # ARCHITECTURE.md §Notas: stock_lock_timestamp para reserva temporária
    stock_lock_timestamp: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), onupdate=datetime.utcnow
    )

    # Relationships
    product = relationship("Product", back_populates="variants")
    reservations = relationship("StockReservation", back_populates="sku_variant", lazy="selectin")
