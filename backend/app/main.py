"""
Ponto de entrada do backend Zoe (FastAPI).

Referências:
- ARCHITECTURE.md §Backend Reference (FastAPI): estrutura de routers
- TECHNICAL_AUDIT.md §1.1 Race Conditions: IdempotencyMiddleware
- TECHNICAL_AUDIT.md §1.2 Sincronização de Estoque: middleware de exceção para rollback de lock
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import init_db
from app.core.redis import init_redis, close_redis
from app.core.middleware.idempotency import IdempotencyMiddleware
from app.core.middleware.rate_limiter import RateLimiterMiddleware
from app.core.middleware.exception_handler import register_exception_handlers
from app.api.v1 import (
    auth,
    stores,
    products,
    orders,
    inventory,
    websocket_tracking,
    cart,
    payments,
    coupons,
    reviews,
    wishlists,
    rma,
    users,
    notifications,
)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle: inicializa DB e Redis; encerra conexões ao desligar."""
    await init_db()
    await init_redis()
    yield
    await close_redis()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

# ── CORS ─────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Rate Limiter Middleware (TECHNICAL_AUDIT §1.5) ───────────────────────────
app.add_middleware(RateLimiterMiddleware)

# ── Idempotency Middleware (TECHNICAL_AUDIT §1.1) ────────────────────────────
app.add_middleware(IdempotencyMiddleware)

# ── Exception Handlers (TECHNICAL_AUDIT §1.2 – rollback de stock lock) ──────
register_exception_handlers(app)

# ── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth.router, prefix=f"{settings.API_V1_PREFIX}/auth", tags=["Auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_PREFIX}/users", tags=["Users"])
app.include_router(stores.router, prefix=f"{settings.API_V1_PREFIX}/stores", tags=["Stores"])
app.include_router(products.router, prefix=f"{settings.API_V1_PREFIX}/products", tags=["Products"])
app.include_router(orders.router, prefix=f"{settings.API_V1_PREFIX}/orders", tags=["Orders"])
app.include_router(cart.router, prefix=f"{settings.API_V1_PREFIX}/cart", tags=["Cart"])
app.include_router(payments.router, prefix=f"{settings.API_V1_PREFIX}/payments", tags=["Payments"])
app.include_router(coupons.router, prefix=f"{settings.API_V1_PREFIX}/coupons", tags=["Coupons"])
app.include_router(reviews.router, prefix=f"{settings.API_V1_PREFIX}/reviews", tags=["Reviews"])
app.include_router(wishlists.router, prefix=f"{settings.API_V1_PREFIX}/wishlists", tags=["Wishlists"])
app.include_router(rma.router, prefix=f"{settings.API_V1_PREFIX}/rma", tags=["RMA"])
app.include_router(notifications.router, prefix=f"{settings.API_V1_PREFIX}/notifications", tags=["Notifications"])
app.include_router(inventory.router, prefix=f"{settings.API_V1_PREFIX}/inventory", tags=["Inventory"])
app.include_router(
    websocket_tracking.router,
    prefix=f"{settings.API_V1_PREFIX}/ws",
    tags=["WebSocket"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "version": settings.APP_VERSION}
