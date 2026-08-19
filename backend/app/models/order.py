"""
Models: ORDERS, ORDER_SHIPMENTS, ORDER_ITEMS

Referências:
- ARCHITECTURE.md §ERD: ORDERS, ORDER_SHIPMENTS, ORDER_ITEMS
- ARCHITECTURE.md §Notas de Modelagem:
  - ORDER_SHIPMENTS viabiliza split multi-loja (frete, status e SLA próprios)
  - ORDER_ITEMS aponta para shipment_id (separação logística sem duplicar pedido)
  - ORDERS.idempotency_key garante idempotência em criação de pedidos
- ARCHITECTURE.md §Checkout Crítico: fluxo completo de criação com stock lock
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    String, DateTime, Float, Integer, ForeignKey,
    Enum as SAEnum, Text, Numeric,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    READY_FOR_PICKUP = "ready_for_pickup"
    OUT_FOR_DELIVERY = "out_for_delivery"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"


class ShipmentStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class Order(Base):
    """
    ORDERS: pedido principal do cliente. Contém idempotency_key para evitar duplicidades
    (ARCHITECTURE.md §Headers Obrigatórios).
    """
    __tablename__ = "orders"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    status: Mapped[OrderStatus] = mapped_column(SAEnum(OrderStatus), default=OrderStatus.PENDING)
    payment_status: Mapped[PaymentStatus] = mapped_column(
        SAEnum(PaymentStatus), default=PaymentStatus.PENDING
    )
    subtotal: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    delivery_fee_total: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    discount: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    total: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    coupon_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_address_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("addresses.id"), nullable=True
    )
    # Idempotência (ARCHITECTURE.md §Contratos de API)
    idempotency_key: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="orders")
    shipments = relationship("OrderShipment", back_populates="order", lazy="selectin")
    payments = relationship("Payment", back_populates="order", lazy="selectin")
    rma_requests = relationship("RmaRequest", back_populates="order", lazy="selectin")


class OrderShipment(Base):
    """
    ORDER_SHIPMENTS: split de pedido por loja.
    Cada shipment possui frete, status e SLA independentes
    (ARCHITECTURE.md §Notas de Modelagem).
    """
    __tablename__ = "order_shipments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False, index=True
    )
    store_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stores.id"), nullable=False, index=True
    )
    status: Mapped[ShipmentStatus] = mapped_column(
        SAEnum(ShipmentStatus), default=ShipmentStatus.PENDING
    )
    delivery_fee: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    estimated_delivery: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    order = relationship("Order", back_populates="shipments")
    store = relationship("Store", back_populates="shipments")
    items = relationship("OrderItem", back_populates="shipment", lazy="selectin")


class OrderItem(Base):
    """
    ORDER_ITEMS: vinculado a shipment_id para separação logística
    (ARCHITECTURE.md §Notas de Modelagem).
    """
    __tablename__ = "order_items"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    shipment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("order_shipments.id"), nullable=False, index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=False
    )
    sku_variant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sku_variants.id"), nullable=False
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    total_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    # Relationships
    shipment = relationship("OrderShipment", back_populates="items")
    rma_items = relationship("RmaItem", back_populates="order_item", lazy="selectin")
