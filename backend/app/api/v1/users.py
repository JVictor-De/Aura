"""
Rotas de perfil de usuário.

Referências:
- ARCHITECTURE.md §7: api/v1/users.py
- prompt.md §3.1: Manter endpoints de perfil
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.address import Address

router = APIRouter()


# ── Schemas ──────────────────────────────────────────────────────
class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    phone: str | None = None


class AddressRequest(BaseModel):
    label: str = "Casa"
    street: str
    number: str
    complement: str | None = None
    neighborhood: str
    city: str
    state: str
    zip_code: str
    latitude: float | None = None
    longitude: float | None = None
    is_default: bool = False


class AddressResponse(BaseModel):
    id: str
    label: str
    street: str
    number: str
    complement: str | None
    neighborhood: str
    city: str
    state: str
    zip_code: str
    latitude: float | None
    longitude: float | None
    is_default: bool

    model_config = {"from_attributes": True}


class ProfileResponse(BaseModel):
    id: str
    email: str
    full_name: str | None
    phone: str | None
    role: str

    model_config = {"from_attributes": True}


# ── Profile ──────────────────────────────────────────────────────
@router.get("/me", response_model=ProfileResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    return ProfileResponse(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role),
    )


@router.patch("/me", response_model=ProfileResponse)
async def update_profile(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return ProfileResponse(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role),
    )


# ── Addresses ────────────────────────────────────────────────────
@router.get("/me/addresses", response_model=list[AddressResponse])
async def list_addresses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Address)
        .where(Address.user_id == current_user.id)
        .order_by(Address.is_default.desc(), Address.created_at.desc())
    )
    return [AddressResponse.model_validate(a) for a in result.scalars().all()]


@router.post("/me/addresses", response_model=AddressResponse, status_code=status.HTTP_201_CREATED)
async def add_address(
    data: AddressRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.is_default:
        # Remove default de outros endereços
        existing = await db.execute(
            select(Address).where(Address.user_id == current_user.id, Address.is_default.is_(True))
        )
        for addr in existing.scalars().all():
            addr.is_default = False
            db.add(addr)

    address = Address(
        user_id=current_user.id,
        label=data.label,
        street=data.street,
        number=data.number,
        complement=data.complement,
        neighborhood=data.neighborhood,
        city=data.city,
        state=data.state,
        zip_code=data.zip_code,
        latitude=data.latitude,
        longitude=data.longitude,
        is_default=data.is_default,
    )
    db.add(address)
    await db.commit()
    await db.refresh(address)
    return AddressResponse.model_validate(address)


@router.delete("/me/addresses/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(
    address_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == current_user.id)
    )
    address = result.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    await db.delete(address)
    await db.commit()
