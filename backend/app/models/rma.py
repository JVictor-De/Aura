"""
Models: RMA_REQUESTS e RMA_ITEMS

Referências:
- ARCHITECTURE.md §ERD: RMA_REQUESTS, RMA_ITEMS
- ARCHITECTURE.md §Notas de Modelagem: RMA_ITEMS permite devolução por item
  sem cancelar o pedido inteiro
- ARCHITECTURE.md §Logística Reversa: fluxo completo de RMA
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Integer, ForeignKey, Enum as SAEnum, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class RmaStatus(str, enum.Enum):
    REQUESTED = "requested"
    APPROVED = "approved"
    REJECTED = "rejected"
    SHIPPED_BACK = "shipped_back"
    RECEIVED = "received"
    RESOLVED = "resolved"


class RmaResolution(str, enum.Enum):
    EXCHANGE = "exchange"
    REFUND = "refund"
    STORE_CREDIT = "store_credit"


class RmaRequest(Base):
    __tablename__ = "rma_requests"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False, index=True
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[RmaStatus] = mapped_column(SAEnum(RmaStatus), default=RmaStatus.REQUESTED)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    order = relationship("Order", back_populates="rma_requests")
    items = relationship("RmaItem", back_populates="rma_request", lazy="selectin")


class RmaItem(Base):
    """RMA_ITEMS: devolução por item (ARCHITECTURE.md §Notas de Modelagem)."""
    __tablename__ = "rma_items"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rma_request_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("rma_requests.id"), nullable=False, index=True
    )
    order_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("order_items.id"), nullable=False
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    resolution: Mapped[str | None] = mapped_column(String(30), nullable=True)

    # Relationships
    rma_request = relationship("RmaRequest", back_populates="items")
    order_item = relationship("OrderItem", back_populates="rma_items")
