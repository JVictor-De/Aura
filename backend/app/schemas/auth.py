"""
Schemas de autenticação (Pydantic).

Referências:
- ARCHITECTURE.md §Auth: JWT com role (customer / merchant / admin)
"""

from pydantic import BaseModel, EmailStr, Field
from uuid import UUID


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str = Field(min_length=2, max_length=255)
    phone: str | None = None
    cpf: str | None = None


class MerchantRegisterRequest(RegisterRequest):
    store_name: str = Field(min_length=2, max_length=255)
    cnpj: str = Field(min_length=14, max_length=18)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    phone: str | None
    role: str
    store_id: UUID | None

    model_config = {"from_attributes": True}
