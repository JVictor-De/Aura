"""
Configuração centralizada do backend Zoe.

Referências:
- ARCHITECTURE.md §Backend Reference (FastAPI): estrutura app/config.py
- TECHNICAL_AUDIT.md §1.2 Sincronização de Estoque: RESERVATION_TTL = 900s (15 min)
- TECHNICAL_AUDIT.md §1.4 Single Points of Failure: Redis Sentinel + fallback PostgreSQL
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── App ──────────────────────────────────────────────────────────────
    APP_NAME: str = "Zoe API"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # ── Database (PostgreSQL + PostGIS) ──────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://zoe:zoe_secret@db:5432/zoe"
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10

    # ── Redis ────────────────────────────────────────────────────────────
    REDIS_URL: str = "redis://redis:6379/0"

    # ── JWT / Auth ───────────────────────────────────────────────────────
    JWT_SECRET_KEY: str = "CHANGE-ME-IN-PRODUCTION"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ── Stock Reservation (TECHNICAL_AUDIT §1.2) ────────────────────────
    STOCK_RESERVATION_TTL_SECONDS: int = 900  # 15 minutos

    # ── Idempotency (TECHNICAL_AUDIT §1.1) ──────────────────────────────
    IDEMPOTENCY_TTL_SECONDS: int = 3600  # 1 hora

    # ── CORS ─────────────────────────────────────────────────────────────
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:8080"]

    model_config = {"env_file": ".env", "case_sensitive": True}


@lru_cache()
def get_settings() -> Settings:
    return Settings()
