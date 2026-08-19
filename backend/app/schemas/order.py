"""
Schemas de pedidos e pagamentos (Pydantic).

Referências:
- ARCHITECTURE.md §Contratos de API: POST /orders, POST /payments
- ARCHITECTURE.md §Headers Obrigatórios: X-Idempotency-Key obrigatório
"""

from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


# ── Orders ───────────────────────────────────────────────────────────────────

class OrderItemRequest(BaseModel):
    sku: str
    quantity: int = Field(ge=1)


class CreateOrderRequest(BaseModel):
    cart_id: UUID | None = None
    address_id: UUID
    payment_method: str = "card"
    items: list[OrderItemRequest]


class ShipmentResponse(BaseModel):
    shipment_id: UUID
    store_id: UUID
    delivery_fee: float
    status: str

    model_config = {"from_attributes": True}


class CreateOrderResponse(BaseModel):
    order_id: UUID
    shipments: list[ShipmentResponse]
    payment_id: UUID
    payment_status: str


class OrderItemResponse(BaseModel):
    id: UUID
    product_id: UUID
    sku_variant_id: UUID
    quantity: int
    unit_price: float
    total_price: float

    model_config = {"from_attributes": True}


class OrderResponse(BaseModel):
    id: UUID
    user_id: UUID
    status: str
    payment_status: str
    subtotal: float
    delivery_fee_total: float
    discount: float
    total: float
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Payments ─────────────────────────────────────────────────────────────────

class CreatePaymentRequest(BaseModel):
    order_id: UUID
    amount: float
    provider: str = "stripe"
    payment_method_token: str


class PaymentResponse(BaseModel):
    payment_id: UUID
    status: str
    provider_reference: str | None

    model_config = {"from_attributes": True}
