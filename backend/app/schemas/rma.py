"""
Schemas de RMA (devoluções/trocas).

Referências:
- ARCHITECTURE.md §2.4: Logística Reversa Fácil
- ARCHITECTURE.md §ERD: RMA_REQUESTS, RMA_ITEMS
"""

from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


class RmaItemRequest(BaseModel):
    order_item_id: UUID
    quantity: int = Field(ge=1)
    reason: str = Field(default="changed_mind")


class CreateRmaRequest(BaseModel):
    order_id: UUID
    reason: str = Field(min_length=5, max_length=500)
    items: list[RmaItemRequest] = Field(min_length=1)


class RmaItemResponse(BaseModel):
    id: UUID
    order_item_id: UUID
    quantity: int
    resolution: str | None

    model_config = {"from_attributes": True}


class RmaResponse(BaseModel):
    id: UUID
    order_id: UUID
    reason: str
    status: str
    items: list[RmaItemResponse] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class RmaEligibilityResponse(BaseModel):
    eligible: bool
    reason: str | None = None
