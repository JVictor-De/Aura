"""
Model: DELIVERY_TRACKING

Referências:
- ARCHITECTURE.md §ERD: DELIVERY_TRACKING
- ARCHITECTURE.md §2.3: Rastreamento em Tempo Real
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class TrackingStatus(str, enum.Enum):
    ASSIGNED = "assigned"
    PICKING_UP = "picking_up"
    EN_ROUTE = "en_route"
    ARRIVING = "arriving"
    DELIVERED = "delivered"


class DeliveryTracking(Base):
    __tablename__ = "delivery_tracking"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id"), unique=True, nullable=False
    )
    driver_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    driver_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    current_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    current_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[TrackingStatus] = mapped_column(
        SAEnum(TrackingStatus), default=TrackingStatus.ASSIGNED
    )
    estimated_arrival: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), onupdate=datetime.utcnow
    )

    # Relationships
    order = relationship("Order")
