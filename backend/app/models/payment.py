"""
Models: PAYMENTS e PAYMENT_EVENTS

Referências:
- ARCHITECTURE.md §ERD: PAYMENTS, PAYMENT_EVENTS
- ARCHITECTURE.md §Notas de Modelagem: PAYMENTS.idempotency_key garante idempotência
  em cobranças e reprocessamento de webhooks
- ARCHITECTURE.md §Checkout Crítico: webhook do gateway → PAYMENT_EVENTS → atualiza PAYMENTS
- TECHNICAL_AUDIT.md §1.4: circuit breaker + retry com backoff exponencial
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Enum as SAEnum, Text, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class PaymentProvider(str, enum.Enum):
    STRIPE = "stripe"
    PIX = "pix"
    CREDIT_CARD = "credit_card"


class PaymentEventType(str, enum.Enum):
    CREATED = "created"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"
    DISPUTE = "dispute"


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False, index=True
    )
    provider: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="pending")
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    # Idempotência para cobranças (ARCHITECTURE.md §Notas de Modelagem)
    idempotency_key: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    provider_reference: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    order = relationship("Order", back_populates="payments")
    events = relationship("PaymentEvent", back_populates="payment", lazy="selectin")


class PaymentEvent(Base):
    """
    PAYMENT_EVENTS: log imutável de eventos do gateway.
    Usado para reconciliação quando webhook não chega (ARCHITECTURE.md §Checkout Crítico §8).
    """
    __tablename__ = "payment_events"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("payments.id"), nullable=False, index=True
    )
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=True)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    payment = relationship("Payment", back_populates="events")
