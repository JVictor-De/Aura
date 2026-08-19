"""
Schemas de pagamento (Pydantic).

Referências:
- ARCHITECTURE.md §ERD: PAYMENTS, PAYMENT_EVENTS
- ARCHITECTURE.md §Checkout Crítico: webhook do gateway
"""

from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


class CreatePaymentRequest(BaseModel):
    order_id: UUID
    amount: float = Field(gt=0)
    provider: str = "stripe"
    payment_method_token: str = ""


class PaymentResponse(BaseModel):
    id: UUID
    order_id: UUID
    status: str
    amount: float
    provider: str
    provider_reference: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class PaymentEventResponse(BaseModel):
    id: UUID
    payment_id: UUID
    type: str
    received_at: datetime

    model_config = {"from_attributes": True}


class WebhookPayload(BaseModel):
    """Payload do webhook do gateway de pagamento."""
    payment_id: UUID
    event_type: str
    gateway_transaction_id: str | None = None
    raw_payload: dict = {}
