"""
Rotas de wishlist (favoritos).

Referências:
- ARCHITECTURE.md §2.5: Wishlist (Favoritos)
- ARCHITECTURE.md §ERD: WISHLISTS
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.wishlist import Wishlist
from app.models.product import Product

router = APIRouter()


class WishlistItemResponse(BaseModel):
    id: UUID
    product_id: UUID
    product_name: str
    brand: str
    base_price: float
    image_url: str | None = None
    created_at: str

    model_config = {"from_attributes": True}


class AddWishlistRequest(BaseModel):
    product_id: UUID


@router.get("/", response_model=list[WishlistItemResponse])
async def get_wishlist(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Lista favoritos do usuário."""
    stmt = (
        select(Wishlist, Product)
        .join(Product, Wishlist.product_id == Product.id)
        .where(Wishlist.user_id == current_user.id)
        .order_by(Wishlist.created_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()

    return [
        WishlistItemResponse(
            id=w.id,
            product_id=w.product_id,
            product_name=p.name,
            brand=p.brand,
            base_price=p.base_price,
            created_at=str(w.created_at),
        )
        for w, p in rows
    ]


@router.post("/", status_code=201)
async def add_to_wishlist(
    data: AddWishlistRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Adiciona produto aos favoritos."""
    # Verificar duplicata
    existing = await db.execute(
        select(Wishlist).where(
            Wishlist.user_id == current_user.id,
            Wishlist.product_id == data.product_id,
        )
    )
    if existing.scalar_one_or_none():
        return {"detail": "Already in wishlist"}

    wish = Wishlist(
        user_id=current_user.id,
        product_id=data.product_id,
    )
    db.add(wish)
    await db.flush()
    return {"detail": "Added to wishlist", "id": str(wish.id)}


@router.delete("/{product_id}")
async def remove_from_wishlist(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove produto dos favoritos."""
    result = await db.execute(
        select(Wishlist).where(
            Wishlist.user_id == current_user.id,
            Wishlist.product_id == product_id,
        )
    )
    wish = result.scalar_one_or_none()
    if not wish:
        raise HTTPException(status_code=404, detail="Not in wishlist")
    await db.delete(wish)
    return {"detail": "Removed from wishlist"}
