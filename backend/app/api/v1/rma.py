"""
Rotas de RMA (devoluções).

Referências:
- ARCHITECTURE.md §2.4: Logística Reversa Fácil
- ARCHITECTURE.md §7: api/v1/rma.py
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.rma import RmaRequest, RmaStatus
from app.schemas.rma import (
    CreateRmaRequest,
    RmaResponse,
    RmaEligibilityResponse,
)
from app.services.rma_service import RmaService

router = APIRouter()


@router.get("/check/{order_id}", response_model=RmaEligibilityResponse)
async def check_rma_eligibility(
    order_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Verifica se o pedido pode ser devolvido."""
    service = RmaService(db)
    result = await service.can_request_rma(order_id, current_user.id)
    return RmaEligibilityResponse(**result)


@router.post("/", response_model=RmaResponse, status_code=201)
async def create_rma(
    data: CreateRmaRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Solicita devolução por item.
    ARCHITECTURE.md §2.4: "flow de um clique para Solicitar Devolução por item individual"
    """
    service = RmaService(db)
    try:
        rma = await service.create_rma_request(
            order_id=data.order_id,
            user_id=current_user.id,
            items=[item.model_dump() for item in data.items],
            reason=data.reason,
        )
        return rma
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/", response_model=list[RmaResponse])
async def list_rma_requests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Lista solicitações de devolução do usuário ou da loja."""
    if current_user.role == UserRole.MERCHANT and current_user.store_id:
        # Lojista: RMAs dos pedidos da sua loja
        from app.models.order import Order, OrderShipment
        stmt = (
            select(RmaRequest)
            .join(Order, RmaRequest.order_id == Order.id)
            .join(OrderShipment, Order.id == OrderShipment.order_id)
            .where(OrderShipment.store_id == current_user.store_id)
            .distinct()
        )
    else:
        # Cliente: suas próprias RMAs (via order_id → user_id)
        from app.models.order import Order
        stmt = (
            select(RmaRequest)
            .join(Order, RmaRequest.order_id == Order.id)
            .where(Order.user_id == current_user.id)
        )

    result = await db.execute(stmt.order_by(RmaRequest.created_at.desc()))
    return result.scalars().all()


@router.patch("/{rma_id}/approve", response_model=RmaResponse)
async def approve_rma(
    rma_id: UUID,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Aprova devolução (lojista/admin)."""
    service = RmaService(db)
    try:
        return await service.approve_rma(rma_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{rma_id}/reject", response_model=RmaResponse)
async def reject_rma(
    rma_id: UUID,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Rejeita devolução (lojista/admin)."""
    service = RmaService(db)
    try:
        return await service.reject_rma(rma_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{rma_id}/complete", response_model=RmaResponse)
async def complete_rma(
    rma_id: UUID,
    current_user: User = Depends(require_role(UserRole.MERCHANT, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """Conclui devolução e restock (lojista/admin)."""
    service = RmaService(db)
    try:
        return await service.complete_rma(rma_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
