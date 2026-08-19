"""
Schemas de carrinho (Pydantic).

Referências:
- ARCHITECTURE.md §ERD: CART_SESSIONS, CART_ITEMS
- ARCHITECTURE.md §8.2: Single-store lock no MVP
- TECHNICAL_AUDIT.md §2.4: confirmação ao trocar de loja
"""

from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


class AddToCartRequest(BaseModel):
    sku: str = Field(min_length=1)
    quantity: int = Field(ge=1, default=1)
    store_id: UUID


class UpdateCartItemRequest(BaseModel):
    quantity: int = Field(ge=1)


class CartItemResponse(BaseModel):
    id: UUID
    sku_variant_id: UUID
    sku: str
    product_name: str
    size: str
    color: str
    quantity: int
    unit_price: float
    total_price: float
    image_url: str | None = None
    reservation_expires_at: datetime | None = None

    model_config = {"from_attributes": True}


class CartSessionResponse(BaseModel):
    id: UUID
    store_id: UUID
    store_name: str
    status: str
    items: list[CartItemResponse] = []
    subtotal: float
    item_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class CartStoreConflictResponse(BaseModel):
    """Resposta quando cliente tenta adicionar item de loja diferente."""
    current_store_id: UUID
    current_store_name: str
    new_store_id: UUID
    new_store_name: str
    message: str = "Seu carrinho contém itens de outra loja. Deseja limpar e continuar?"


class ClearCartAndAddRequest(BaseModel):
    """Confirma limpeza do carrinho atual e adiciona item de nova loja."""
    sku: str
    quantity: int = Field(ge=1, default=1)
    new_store_id: UUID
    confirm_clear: bool = True
