"""
Rotas de autenticação: registro e login diferenciados por role.

Referências:
- ARCHITECTURE.md §Auth: clientes vs lojistas
- ARCHITECTURE.md §Backend Reference: api/v1/auth.py
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import (
    LoginRequest, RegisterRequest, MerchantRegisterRequest,
    TokenResponse, RefreshTokenRequest, UserResponse,
)
from app.services.auth_service import AuthService
from app.core.security import get_current_user, decode_token, create_access_token
from app.models.user import User

router = APIRouter()


@router.post("/register/customer", response_model=TokenResponse)
async def register_customer(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Registro de cliente final (role=CUSTOMER)."""
    try:
        service = AuthService(db)
        return await service.register_customer(data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/register/merchant", response_model=TokenResponse)
async def register_merchant(data: MerchantRegisterRequest, db: AsyncSession = Depends(get_db)):
    """Registro de lojista com store associada (role=MERCHANT)."""
    try:
        service = AuthService(db)
        return await service.register_merchant(data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    try:
        service = AuthService(db)
        return await service.login(data)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Renova access_token usando refresh_token (TECHNICAL_AUDIT §1.4)."""
    payload = decode_token(data.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    from sqlalchemy import select
    from uuid import UUID
    result = await db.execute(select(User).where(User.id == UUID(payload["sub"])))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role.value),
        refresh_token=data.refresh_token,
        role=user.role.value,
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
