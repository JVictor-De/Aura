"""
Rotas de pagamento com webhooks idempotentes.

Referências:
- ARCHITECTURE.md §Checkout Crítico: webhook do gateway → PAYMENT_EVENTS
- ARCHITECTURE.md §7: api/v1/payments.py — Webhooks idempotentes
- TECHNICAL_AUDIT.md §5.3: Reexecução segura (idempotência)
"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user
from app.core.redis import get_redis
from app.models.user import User
from app.models.payment import Payment, PaymentEvent
from app.schemas.payment import (
    CreatePaymentRequest,
    PaymentResponse,
    WebhookPayload,
)
from app.services.payment_service import PaymentService

router = APIRouter()


@router.post("/", response_model=PaymentResponse)
async def create_payment(
    data: CreatePaymentRequest,
    x_idempotency_key: str = Header(..., alias="X-Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Cria intent de pagamento com idempotência.
    TECHNICAL_AUDIT.md §5.3: mesma key retorna resultado original.
    """
    redis = get_redis()
    service = PaymentService(db, redis)

    payment = await service.create_payment(
        order_id=data.order_id,
        amount=data.amount,
        provider=data.provider,
        idempotency_key=x_idempotency_key,
    )

    if isinstance(payment, dict):
        # Replay de idempotência
        return payment

    return payment


@router.post("/webhook")
async def payment_webhook(
    payload: WebhookPayload,
    db: AsyncSession = Depends(get_db),
):
    """
    Webhook do gateway de pagamento.
    ARCHITECTURE.md §Checkout Crítico §5: webhook → PAYMENT_EVENTS → atualiza PAYMENTS.
    Endpoint público (autenticado por assinatura do gateway em produção).
    """
    redis = get_redis()
    service = PaymentService(db, redis)

    await service.handle_webhook(
        payment_id=payload.payment_id,
        event_type=payload.event_type,
        payload=payload.raw_payload,
    )

    return {"status": "processed"}


@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment(
    payment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Consulta status de um pagamento."""
    result = await db.execute(
        select(Payment).where(Payment.id == uuid.UUID(payment_id))
    )
    payment = result.scalar_one_or_none()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    return payment
