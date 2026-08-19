"""
Model: STORES

Referências:
- ARCHITECTURE.md §ERD: STORES { uuid id PK, text name, text cnpj, text status, timestamptz created_at }
- ARCHITECTURE.md §Store Entity: name, cnpj, description, logoUrl, bannerUrl, address, coordinates, rating
- TECHNICAL_AUDIT.md §1.3: coluna geohash para cache geoespacial otimizado
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, Integer, Boolean, Text, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class StoreStatus(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    cnpj: Mapped[str] = mapped_column(String(18), unique=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    banner_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Endereço embarcado
    address_street: Mapped[str] = mapped_column(String(255), nullable=False)
    address_city: Mapped[str] = mapped_column(String(100), nullable=False)
    address_state: Mapped[str] = mapped_column(String(2), nullable=False)
    address_zip: Mapped[str] = mapped_column(String(10), nullable=False)

    # Geolocalização (TECHNICAL_AUDIT §1.3 – PostGIS + geohash)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    geohash: Mapped[str | None] = mapped_column(String(12), index=True, nullable=True)

    rating: Mapped[float] = mapped_column(Float, default=0.0)
    review_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[StoreStatus] = mapped_column(SAEnum(StoreStatus), default=StoreStatus.ACTIVE)
    is_open: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    # Relationships
    products = relationship("Product", back_populates="store", lazy="selectin")
    shipments = relationship("OrderShipment", back_populates="store", lazy="selectin")
