"""
Rate Limiter middleware com Redis.

Referências:
- TECHNICAL_AUDIT.md §R8: Abuso de autenticação (brute force)
- TECHNICAL_AUDIT.md §4.1.D: Rate limiting por IP/rota
  - /api/v1/auth/login: 5 req/min por IP
  - rotas públicas: 100 req/min por IP
- ARCHITECTURE.md §7: core/middleware/rate_limiter.py
"""

import time
import logging

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from app.core.redis import get_redis

logger = logging.getLogger("zoe.rate_limiter")

# Configuração de limites por rota (TECHNICAL_AUDIT §4.1.D)
RATE_LIMITS: dict[str, tuple[int, int]] = {
    # path_prefix: (max_requests, window_seconds)
    "/api/v1/auth/login": (5, 60),
    "/api/v1/auth/register": (3, 60),
    "/api/v1/auth/refresh": (10, 60),
}

# Limite padrão para rotas públicas
DEFAULT_RATE_LIMIT = (100, 60)  # 100 req/min


class RateLimiterMiddleware(BaseHTTPMiddleware):
    """
    Rate limiting com sliding window counter no Redis.

    TECHNICAL_AUDIT §R8: prevenção de brute force em /auth/login.
    Usa IP do cliente como chave. Em produção, considerar X-Forwarded-For.
    """

    async def dispatch(self, request: Request, call_next):
        # Ignorar health check e métodos seguros para OPTIONS
        if request.url.path == "/health" or request.method == "OPTIONS":
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path

        # Encontrar limite específico da rota
        max_requests, window = DEFAULT_RATE_LIMIT
        for route_prefix, limit in RATE_LIMITS.items():
            if path.startswith(route_prefix):
                max_requests, window = limit
                break

        try:
            redis = get_redis()
            key = f"rate_limit:{client_ip}:{path}"
            now = time.time()
            window_start = now - window

            pipe = redis.pipeline()
            # Remover entradas fora da janela
            pipe.zremrangebyscore(key, 0, window_start)
            # Adicionar request atual
            pipe.zadd(key, {str(now): now})
            # Contar requests na janela
            pipe.zcard(key)
            # Definir expiração da chave
            pipe.expire(key, window)
            results = await pipe.execute()

            request_count = results[2]

            if request_count > max_requests:
                logger.warning(
                    "Rate limit exceeded: IP=%s path=%s count=%d limit=%d",
                    client_ip, path, request_count, max_requests,
                )
                retry_after = int(window - (now - window_start))
                return JSONResponse(
                    status_code=429,
                    content={
                        "code": "RATE_LIMIT_EXCEEDED",
                        "message": "Muitas requisições. Tente novamente em alguns minutos.",
                        "details": {"retry_after_seconds": max(retry_after, 1)},
                    },
                    headers={"Retry-After": str(max(retry_after, 1))},
                )
        except Exception as e:
            # Se Redis falhar, permitir a requisição (fail-open)
            logger.error("Rate limiter Redis error: %s", str(e))

        return await call_next(request)
