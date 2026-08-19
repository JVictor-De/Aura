"""
Dependency de tenant (RLS) para isolamento multi-tenant.

Referências:
- ARCHITECTURE.md §3.1: RLS nativa do PostgreSQL
- TECHNICAL_AUDIT.md §2.1: Isolamento por store_id em duas camadas
- TECHNICAL_AUDIT.md §4.1.C: merchant sempre escopado a store_id
"""

from uuid import UUID
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User, UserRole


async def set_tenant_context(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AsyncSession:
    """
    Injeta store_id na sessão PostgreSQL para RLS.

    ARCHITECTURE.md §3.1: "Injetamos o tenant_id (store_id) na Transaction Session
    via JWT antes de cada transação."

    Em produção, o PostgreSQL deve ter políticas RLS criadas via Alembic:
    ALTER TABLE products ENABLE ROW LEVEL SECURITY;
    CREATE POLICY products_store_isolation ON products
      USING (store_id = current_setting('app.current_store_id')::uuid);
    """
    if current_user.role == UserRole.MERCHANT:
        if not current_user.store_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Merchant user has no store assigned",
            )
        # Setar variável de sessão para RLS
        await db.execute(
            text("SET LOCAL app.current_store_id = :store_id"),
            {"store_id": str(current_user.store_id)},
        )
    elif current_user.role == UserRole.ADMIN:
        # Admin tem acesso global — setar variável vazia para bypass
        await db.execute(
            text("SET LOCAL app.current_store_id = ''"),
        )

    return db


def get_merchant_store_id(
    current_user: User = Depends(get_current_user),
) -> UUID:
    """
    Extrai store_id do merchant autenticado.
    Útil para queries que precisam do filtro explícito além do RLS.
    """
    if current_user.role == UserRole.MERCHANT:
        if not current_user.store_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No store assigned to this merchant",
            )
        return current_user.store_id
    elif current_user.role == UserRole.ADMIN:
        # Admin pode operar em qualquer loja
        return None  # type: ignore
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only merchants and admins can access this resource",
        )
