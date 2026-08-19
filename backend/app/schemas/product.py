"""
Schemas de produto e inventário.
"""

from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime


class SkuVariantResponse(BaseModel):
    id: UUID
    sku: str
    size: str
    color: str
    color_hex: str
    stock_quantity: int
    price: float
    image_url: str | None
    is_available: bool

    model_config = {"from_attributes": True}


class ProductResponse(BaseModel):
    id: UUID
    store_id: UUID
    name: str
    description: str | None
    brand: str
    category: str
    base_price: float
    discount_price: float | None
    is_active: bool
    variants: list[SkuVariantResponse] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateProductRequest(BaseModel):
    name: str = Field(min_length=2, max_length=255)
    description: str | None = None
    brand: str = Field(min_length=1, max_length=100)
    category: str
    base_price: float = Field(gt=0)
    discount_price: float | None = None
    material: str | None = None
    fit: str | None = None


class CreateSkuVariantRequest(BaseModel):
    sku: str = Field(min_length=1, max_length=50)
    size: str
    color: str
    color_hex: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    stock_quantity: int = Field(ge=0)
    price: float = Field(gt=0)
    image_url: str | None = None


class UpdateStockRequest(BaseModel):
    stock_quantity: int = Field(ge=0)


class StoreResponse(BaseModel):
    id: UUID
    name: str
    cnpj: str
    description: str | None
    logo_url: str | None
    status: str
    lat: float
    lng: float
    rating: float
    is_open: bool

    model_config = {"from_attributes": True}
