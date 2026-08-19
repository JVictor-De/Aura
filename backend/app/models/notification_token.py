"""
Model: NOTIFICATION_TOKENS

Referências:
- ARCHITECTURE.md §ERD: NOTIFICATION_TOKENS
- ARCHITECTURE.md §2.6: Notificações Push + In-App via FCM
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Boolean, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class Platform(str, enum.Enum):
    IOS = "ios"
    ANDROID = "android"
    WEB = "web"


class NotificationToken(Base):
    __tablename__ = "notification_tokens"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    token: Mapped[str] = mapped_column(String(512), nullable=False)
    platform: Mapped[Platform] = mapped_column(SAEnum(Platform), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Relationships
    user = relationship("User")
