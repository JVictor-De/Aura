"""
Auth Service: registro e login diferenciados para clientes e lojistas.

Referências:
- ARCHITECTURE.md §Auth: "diferencie autenticação para clientes e lojistas"
- ARCHITECTURE.md §User Entity: AuthProvider (email, google, apple)
"""

from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole, AuthProvider
from app.models.store import Store, StoreStatus
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from app.schemas.auth import (
    LoginRequest, RegisterRequest, MerchantRegisterRequest,
    TokenResponse, UserResponse,
)


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_customer(self, data: RegisterRequest) -> TokenResponse:
        """Registra um cliente (role=CUSTOMER)."""
        await self._ensure_email_available(data.email)

        user = User(
            email=data.email,
            hashed_password=hash_password(data.password),
            name=data.name,
            phone=data.phone,
            cpf=data.cpf,
            role=UserRole.CUSTOMER,
            auth_provider=AuthProvider.EMAIL,
        )
        self.db.add(user)
        await self.db.flush()

        return self._build_tokens(user)

    async def register_merchant(self, data: MerchantRegisterRequest) -> TokenResponse:
        """
        Registra um lojista com store associada.
        O user.store_id é preenchido para que o RBAC filtre pedidos por loja
        (ARCHITECTURE.md §Auth).
        """
        await self._ensure_email_available(data.email)

        store = Store(
            name=data.store_name,
            cnpj=data.cnpj,
            address_street="",
            address_city="",
            address_state="SP",
            address_zip="00000-000",
            lat=0.0,
            lng=0.0,
            status=StoreStatus.ACTIVE,
        )
        self.db.add(store)
        await self.db.flush()

        user = User(
            email=data.email,
            hashed_password=hash_password(data.password),
            name=data.name,
            phone=data.phone,
            cpf=data.cpf,
            role=UserRole.MERCHANT,
            auth_provider=AuthProvider.EMAIL,
            store_id=store.id,
        )
        self.db.add(user)
        await self.db.flush()

        return self._build_tokens(user)

    async def login(self, data: LoginRequest) -> TokenResponse:
        result = await self.db.execute(select(User).where(User.email == data.email))
        user = result.scalar_one_or_none()

        if not user or not verify_password(data.password, user.hashed_password):
            raise ValueError("Invalid email or password")

        return self._build_tokens(user)

    async def _ensure_email_available(self, email: str):
        result = await self.db.execute(select(User).where(User.email == email))
        if result.scalar_one_or_none():
            raise ValueError("Email already registered")

    @staticmethod
    def _build_tokens(user: User) -> TokenResponse:
        return TokenResponse(
            access_token=create_access_token(str(user.id), user.role.value),
            refresh_token=create_refresh_token(str(user.id)),
            role=user.role.value,
        )
