"""
Rotas de notificações.

Referências:
- ARCHITECTURE.md §2.6: Notificações Push + In-App
- ARCHITECTURE.md §7: api/v1/notifications.py
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services.notification_service import NotificationService

router = APIRouter()


class RegisterTokenRequest(BaseModel):
    token: str
    platform: str = "android"


class DeactivateTokenRequest(BaseModel):
    token: str


@router.post("/register-token")
async def register_notification_token(
    data: RegisterTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Registra token FCM do dispositivo."""
    service = NotificationService(db)
    nt = await service.register_token(
        user_id=current_user.id,
        token=data.token,
        platform=data.platform,
    )
    return {"detail": "Token registered", "id": str(nt.id)}


@router.post("/deactivate-token")
async def deactivate_notification_token(
    data: DeactivateTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Desativa token FCM (logout/uninstall)."""
    service = NotificationService(db)
    await service.deactivate_token(data.token)
    return {"detail": "Token deactivated"}
