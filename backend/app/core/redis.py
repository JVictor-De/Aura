"""
Conexão Redis assíncrona para cache, idempotência e reservas de estoque.

Referências:
- TECHNICAL_AUDIT.md §1.1: cache de idempotency_key no Redis (TTL 1h)
- TECHNICAL_AUDIT.md §1.2: Reservas temporárias com TTL 15min no Redis
- TECHNICAL_AUDIT.md §1.4: Redis Sentinel para HA (configurável)
"""

import redis.asyncio as aioredis
from app.config import get_settings

settings = get_settings()

redis_client: aioredis.Redis | None = None


async def init_redis():
    global redis_client
    redis_client = aioredis.from_url(
        settings.REDIS_URL,
        decode_responses=True,
    )


async def close_redis():
    global redis_client
    if redis_client:
        await redis_client.close()


def get_redis() -> aioredis.Redis:
    if redis_client is None:
        raise RuntimeError("Redis not initialized. Call init_redis() first.")
    return redis_client
