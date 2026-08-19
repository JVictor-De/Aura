"""
Notification Service: push via FCM e in-app notifications.

Referências:
- ARCHITECTURE.md §2.6: Notificações Push + In-App
- ARCHITECTURE.md §ERD: NOTIFICATION_TOKENS
"""

import logging
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification_token import NotificationToken

logger = logging.getLogger("zoe.notification_service")


class NotificationService:
    """
    Serviço de notificações push (FCM) e in-app.

    ARCHITECTURE.md §2.6: "Se o push falhar (permissão negada),
    o app mantém um Notification Center interno com badge no ícone."

    No MVP, este serviço registra tokens e simula envio de push.
    Em produção, integrar com firebase-admin SDK.
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_token(
        self, user_id: UUID, token: str, platform: str
    ) -> NotificationToken:
        """Registra/atualiza token FCM de um dispositivo."""
        # Verificar se token já existe
        result = await self.db.execute(
            select(NotificationToken).where(
                NotificationToken.user_id == user_id,
                NotificationToken.token == token,
            )
        )
        existing = result.scalar_one_or_none()

        if existing:
            existing.is_active = True
            await self.db.flush()
            return existing

        nt = NotificationToken(
            user_id=user_id,
            token=token,
            platform=platform,
            is_active=True,
        )
        self.db.add(nt)
        await self.db.flush()
        return nt

    async def deactivate_token(self, token: str) -> None:
        """Desativa token (uninstall, logout)."""
        result = await self.db.execute(
            select(NotificationToken).where(NotificationToken.token == token)
        )
        existing = result.scalar_one_or_none()
        if existing:
            existing.is_active = False
            await self.db.flush()

    async def send_push(
        self,
        user_id: UUID,
        title: str,
        body: str,
        data: dict | None = None,
    ) -> bool:
        """
        Envia push notification para todos os dispositivos do usuário.

        No MVP, loga a notificação. Em produção usar:
        from firebase_admin import messaging
        messaging.send(message)
        """
        result = await self.db.execute(
            select(NotificationToken).where(
                NotificationToken.user_id == user_id,
                NotificationToken.is_active == True,
            )
        )
        tokens = result.scalars().all()

        if not tokens:
            logger.info(
                "No active tokens for user %s — notification stored in-app only", user_id
            )
            return False

        for token_record in tokens:
            # Em produção: firebase_admin.messaging.send()
            logger.info(
                "Push [%s] → %s: %s - %s",
                token_record.platform.value,
                user_id,
                title,
                body,
            )

        return True

    async def notify_order_status(
        self, user_id: UUID, order_id: str, status: str
    ) -> None:
        """Notifica mudança de status do pedido."""
        status_messages = {
            "confirmed": ("Pedido aceito! 🎉", "Sua compra foi confirmada pela loja."),
            "preparing": ("Preparando seu pedido 📦", "A loja está separando seus itens."),
            "out_for_delivery": ("Saiu para entrega! 🚗", "Seu pedido está a caminho."),
            "delivered": ("Entregue! ✅", "Seu pedido foi entregue com sucesso."),
        }

        if status in status_messages:
            title, body = status_messages[status]
            await self.send_push(
                user_id=user_id,
                title=title,
                body=body,
                data={"order_id": order_id, "status": status},
            )
