"""
Rotas de avaliações (reviews).

Referências:
- ARCHITECTURE.md §2.5: Wishlist e Social Proof (Reviews)
- ARCHITECTURE.md §ERD: REVIEWS — duplo rate (produto + entrega)
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.review import Review
from app.models.order import Order, OrderStatus

router = APIRouter()


class CreateReviewRequest(BaseModel):
    product_id: UUID
    order_id: UUID
    rating_product: int = Field(ge=1, le=5)
    rating_delivery: int = Field(ge=1, le=5)
    comment: str | None = None


class ReviewResponse(BaseModel):
    id: UUID
    user_id: UUID
    product_id: UUID
    rating_product: int
    rating_delivery: int
    comment: str | None
    is_visible: bool
    created_at: str

    model_config = {"from_attributes": True}


@router.post("/", response_model=ReviewResponse, status_code=201)
async def create_review(
    data: CreateReviewRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Cria avaliação após entrega.
    ARCHITECTURE.md §2.5: "Após a entrega, solicitação de duplo rate."
    Garante que o usuário comprou o produto (order_id).
    """
    # Verificar se o pedido existe e foi entregue
    result = await db.execute(
        select(Order).where(
            Order.id == data.order_id,
            Order.user_id == current_user.id,
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status != OrderStatus.DELIVERED:
        raise HTTPException(status_code=400, detail="Order not yet delivered")

    # Verificar duplicata
    existing = await db.execute(
        select(Review).where(
            Review.user_id == current_user.id,
            Review.product_id == data.product_id,
            Review.order_id == data.order_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already reviewed")

    review = Review(
        user_id=current_user.id,
        product_id=data.product_id,
        order_id=data.order_id,
        rating_product=data.rating_product,
        rating_delivery=data.rating_delivery,
        comment=data.comment,
    )
    db.add(review)
    await db.flush()
    return review


@router.get("/product/{product_id}", response_model=list[ReviewResponse])
async def get_product_reviews(
    product_id: UUID,
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Lista avaliações de um produto."""
    stmt = (
        select(Review)
        .where(Review.product_id == product_id, Review.is_visible == True)
        .order_by(Review.created_at.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/product/{product_id}/summary")
async def get_review_summary(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Média de avaliações de um produto."""
    result = await db.execute(
        select(
            func.count(Review.id),
            func.avg(Review.rating_product),
            func.avg(Review.rating_delivery),
        ).where(
            Review.product_id == product_id,
            Review.is_visible == True,
        )
    )
    row = result.one()
    return {
        "total_reviews": row[0] or 0,
        "avg_rating_product": round(float(row[1] or 0), 1),
        "avg_rating_delivery": round(float(row[2] or 0), 1),
    }


@router.patch("/{review_id}/visibility")
async def toggle_review_visibility(
    review_id: UUID,
    visible: bool = True,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Moderação de avaliação (lojista/admin)."""
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    review.is_visible = visible
    return {"detail": f"Review visibility set to {visible}"}
