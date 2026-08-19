"""
WebSocket para rastreio de pedidos em tempo real.

Referências:
- ARCHITECTURE.md §WebSocket para Real-time Updates
- TECHNICAL_AUDIT.md §1.4: WebSocket com fallback para polling (30s)
- prompt.md §3: painel de pedidos em tempo real via WebSockets,
  exibindo somente splits confirmados da loja autenticada
"""

import json
import logging
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session_factory
from app.core.security import decode_token
from app.models.user import User, UserRole
from app.models.order import OrderShipment, ShipmentStatus

logger = logging.getLogger("zoe.websocket")

router = APIRouter()

# Gerenciador de conexões ativas
class ConnectionManager:
    def __init__(self):
        # store_id -> list[WebSocket] para notificar lojistas
        self.store_connections: dict[str, list[WebSocket]] = {}
        # user_id -> list[WebSocket] para notificar clientes
        self.user_connections: dict[str, list[WebSocket]] = {}

    async def connect_store(self, store_id: str, ws: WebSocket):
        await ws.accept()
        self.store_connections.setdefault(store_id, []).append(ws)

    async def connect_user(self, user_id: str, ws: WebSocket):
        await ws.accept()
        self.user_connections.setdefault(user_id, []).append(ws)

    def disconnect_store(self, store_id: str, ws: WebSocket):
        if store_id in self.store_connections:
            self.store_connections[store_id].remove(ws)

    def disconnect_user(self, user_id: str, ws: WebSocket):
        if user_id in self.user_connections:
            self.user_connections[user_id].remove(ws)

    async def notify_store(self, store_id: str, data: dict):
        """Envia atualização para todos os WebSockets de uma loja."""
        for ws in self.store_connections.get(store_id, []):
            try:
                await ws.send_json(data)
            except Exception:
                pass

    async def notify_user(self, user_id: str, data: dict):
        for ws in self.user_connections.get(user_id, []):
            try:
                await ws.send_json(data)
            except Exception:
                pass


manager = ConnectionManager()


@router.websocket("/orders")
async def websocket_orders(
    websocket: WebSocket,
    token: str = Query(...),
):
    """
    WebSocket para atualizações de pedidos em tempo real.

    Lojistas: recebem somente splits confirmados da sua loja (RBAC).
    Clientes: recebem atualizações dos seus pedidos.
    """
    try:
        payload = decode_token(token)
    except Exception:
        await websocket.close(code=4001, reason="Invalid token")
        return

    user_id = payload.get("sub")
    role = payload.get("role")

    async with async_session_factory() as db:
        result = await db.execute(select(User).where(User.id == UUID(user_id)))
        user = result.scalar_one_or_none()

    if not user:
        await websocket.close(code=4001, reason="User not found")
        return

    if role == UserRole.MERCHANT.value and user.store_id:
        store_id = str(user.store_id)
        await manager.connect_store(store_id, websocket)
        try:
            # Enviar pedidos confirmados iniciais da loja
            async with async_session_factory() as db:
                stmt = (
                    select(OrderShipment)
                    .where(
                        OrderShipment.store_id == user.store_id,
                        OrderShipment.status != ShipmentStatus.CANCELLED,
                    )
                    .order_by(OrderShipment.created_at.desc())
                    .limit(20)
                )
                result = await db.execute(stmt)
                shipments = result.scalars().all()

                await websocket.send_json({
                    "type": "INITIAL_SHIPMENTS",
                    "payload": [
                        {
                            "shipment_id": str(s.id),
                            "order_id": str(s.order_id),
                            "status": s.status.value,
                        }
                        for s in shipments
                    ],
                })

            # Escutar mensagens do lojista (ex: aceitar/rejeitar)
            while True:
                data = await websocket.receive_text()
                msg = json.loads(data)
                logger.info("Store %s WS message: %s", store_id, msg)

        except WebSocketDisconnect:
            manager.disconnect_store(store_id, websocket)
    else:
        # Cliente
        await manager.connect_user(user_id, websocket)
        try:
            while True:
                data = await websocket.receive_text()
                msg = json.loads(data)
                logger.info("User %s WS message: %s", user_id, msg)
        except WebSocketDisconnect:
            manager.disconnect_user(user_id, websocket)
