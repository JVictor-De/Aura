"""
Rotas de inventário (dashboard do lojista).

Referências:
- prompt.md §3 Dashboard Web: gestão de inventário com cadastro de SKUs
  e controle de estoque por variação
- ARCHITECTURE.md §Fluxo do Lojista: Inventário → Adicionar Produtos
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import require_role
from app.models.user import User, UserRole
from app.models.product import Product, SkuVariant
from app.schemas.product import (
    CreateProductRequest, CreateSkuVariantRequest,
    UpdateStockRequest, ProductResponse, SkuVariantResponse,
)

router = APIRouter()


@router.post("/products", response_model=ProductResponse)
async def create_product(
    data: CreateProductRequest,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Cria produto na loja do lojista autenticado."""
    if not current_user.store_id:
        raise HTTPException(status_code=400, detail="User has no store assigned")

    product = Product(
        store_id=current_user.store_id,
        name=data.name,
        description=data.description,
        brand=data.brand,
        category=data.category,
        base_price=data.base_price,
        discount_price=data.discount_price,
        material=data.material,
        fit=data.fit,
    )
    db.add(product)
    await db.flush()
    return product


@router.post("/products/{product_id}/variants", response_model=SkuVariantResponse)
async def create_variant(
    product_id: UUID,
    data: CreateSkuVariantRequest,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Cadastra SKU/variação (cor+tamanho) para um produto."""
    # Verificar que o produto pertence à loja do lojista
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    if product.store_id != current_user.store_id:
        raise HTTPException(status_code=403, detail="Product does not belong to your store")

    variant = SkuVariant(
        product_id=product_id,
        sku=data.sku,
        size=data.size,
        color=data.color,
        color_hex=data.color_hex,
        stock_quantity=data.stock_quantity,
        price=data.price,
        image_url=data.image_url,
    )
    db.add(variant)
    await db.flush()
    return variant


@router.patch("/variants/{variant_id}/stock", response_model=SkuVariantResponse)
async def update_stock(
    variant_id: UUID,
    data: UpdateStockRequest,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Atualiza estoque de uma variação SKU."""
    result = await db.execute(select(SkuVariant).where(SkuVariant.id == variant_id))
    variant = result.scalar_one_or_none()
    if not variant:
        raise HTTPException(status_code=404, detail="Variant not found")

    # RBAC: verificar que a variação pertence à loja do lojista
    product = variant.product
    if product.store_id != current_user.store_id:
        raise HTTPException(status_code=403, detail="Not your store's product")

    variant.stock_quantity = data.stock_quantity
    await db.flush()
    return variant


@router.get("/products", response_model=list[ProductResponse])
async def list_inventory(
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Lista produtos do inventário da loja do lojista autenticado (RBAC)."""
    stmt = select(Product).where(Product.store_id == current_user.store_id)
    result = await db.execute(stmt)
    return result.scalars().all()
