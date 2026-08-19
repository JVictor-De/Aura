"""
Configuração do banco de dados SQLAlchemy assíncrono com PostgreSQL + PostGIS.

Referências:
- ARCHITECTURE.md §ERD (Resumo): tabelas USERS, STORES, PRODUCTS, SKU_VARIANTS,
  ORDERS, ORDER_SHIPMENTS, ORDER_ITEMS, STOCK_RESERVATIONS, PAYMENTS, PAYMENT_EVENTS,
  RMA_REQUESTS, RMA_ITEMS
- ARCHITECTURE.md §Notas de Modelagem: stock_lock_timestamp, reserved_until, idempotency_key
"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    echo=settings.DEBUG,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Base declarativa para todos os modelos do Zoe."""
    pass


async def get_db() -> AsyncSession:
    """Dependency FastAPI: fornece sessão assíncrona com rollback automático em falha."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Cria todas as tabelas (dev only). Em produção usar Alembic."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
