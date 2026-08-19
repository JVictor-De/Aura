"""
Model: STOCK_RESERVATIONS

Referências:
- ARCHITECTURE.md §ERD: STOCK_RESERVATIONS { uuid id PK, uuid sku_variant_id FK,
  uuid user_id FK, int quantity, text status, timestamptz reserved_until, timestamptz created_at }
- ARCHITECTURE.md §Notas de Modelagem: TTL (reserved_until) e status para reconciliação pós-falhas
- TECHNICAL_AUDIT.md §1.2 Sincronização de Estoque:
  - RESERVATION_TTL = 900s (15 min)
  - SELECT FOR UPDATE para evitar overselling
  - Reserva no Redis + registro permanente no PostgreSQL
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Integer, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class ReservationStatus(str, enum.Enum):
    ACTIVE = "active"
    CONFIRMED = "confirmed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class StockReservation(Base):
    __tablename__ = "stock_reservations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sku_variant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sku_variants.id"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[ReservationStatus] = mapped_column(
        SAEnum(ReservationStatus), default=ReservationStatus.ACTIVE
    )
    reserved_until: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    sku_variant = relationship("SkuVariant", back_populates="reservations")
