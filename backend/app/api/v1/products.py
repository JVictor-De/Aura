"""
Rotas de produtos.

Referências:
- ARCHITECTURE.md §Backend Reference: api/v1/products.py
- ARCHITECTURE.md §Product Entity: variações SKU
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.product import Product
from app.schemas.product import ProductResponse
from app.services.search_service import SearchService

router = APIRouter()


@router.get("/", response_model=list[ProductResponse])
async def list_products(
    store_id: UUID = Query(None),
    category: str = Query(None),
    limit: int = Query(50, le=100),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Product).where(Product.is_active == True).limit(limit)
    if store_id:
        stmt = stmt.where(Product.store_id == store_id)
    if category:
        stmt = stmt.where(Product.category == category)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/search", response_model=list[ProductResponse])
async def search_products(
    q: str = Query(""),
    store_id: UUID = Query(None),
    category: str = Query(None),
    size: str = Query(None),
    color: str = Query(None),
    min_price: float = Query(None),
    max_price: float = Query(None),
    brand: str = Query(None),
    limit: int = Query(50, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    """Busca full-text de produtos via pg_trgm + filtros avançados."""
    service = SearchService(db)
    return await service.search_products(
        query=q,
        store_id=str(store_id) if store_id else None,
        category=category,
        size=size,
        color=color,
        min_price=min_price,
        max_price=max_price,
        brand=brand,
        limit=limit,
        offset=offset,
    )


@router.get("/autocomplete")
async def autocomplete(
    q: str = Query("", min_length=2),
    limit: int = Query(8, le=20),
    db: AsyncSession = Depends(get_db),
):
    """Autocomplete para busca de produtos."""
    service = SearchService(db)
    return await service.autocomplete(q, limit)


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
