"""
Idempotency Middleware para FastAPI.

Referências:
- TECHNICAL_AUDIT.md §1.1 Race Conditions no Carrinho Multi-Loja:
  "Usar chave de idempotência (idempotency key) em cada requisição"
  Implementação completa do middleware com Redis (TTL 1h).
- ARCHITECTURE.md §Headers Obrigatórios:
  "X-Idempotency-Key: obrigatório para POST/PATCH em /orders e /payments"
"""

import json
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse

from app.core.redis import get_redis
from app.config import get_settings

settings = get_settings()

# Rotas que exigem X-Idempotency-Key
IDEMPOTENT_ROUTES = {"/api/v1/orders", "/api/v1/payments"}
IDEMPOTENT_METHODS = {"POST", "PUT", "PATCH"}


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """
    Fluxo (TECHNICAL_AUDIT §1.1):
    1. Se o request possui X-Idempotency-Key e é POST/PUT/PATCH:
       a. Consulta Redis pelo cache_key "idempotency:{key}"
       b. Se existir, devolve a resposta cacheada (replay)
       c. Se não, processa o request, cacheia com TTL e devolve
    """

    async def dispatch(self, request: Request, call_next):
        idempotency_key = request.headers.get("X-Idempotency-Key")

        if not idempotency_key or request.method not in IDEMPOTENT_METHODS:
            return await call_next(request)

        # Verificar se a rota exige idempotência
        path = request.url.path
        is_critical = any(path.startswith(route) for route in IDEMPOTENT_ROUTES)

        if not is_critical:
            return await call_next(request)

        redis = get_redis()
        cache_key = f"idempotency:{idempotency_key}"

        # Verificar se já processado
        cached_response = await redis.get(cache_key)
        if cached_response:
            cached = json.loads(cached_response)
            return JSONResponse(
                content=cached["body"],
                status_code=cached["status_code"],
                headers={"X-Idempotency-Replayed": "true"},
            )

        # Processar o request
        response = await call_next(request)

        # Cachear se sucesso (status < 400)
        if response.status_code < 400:
            body = b""
            async for chunk in response.body_iterator:
                body += chunk if isinstance(chunk, bytes) else chunk.encode()

            cache_data = {
                "status_code": response.status_code,
                "body": json.loads(body.decode()),
            }
            await redis.setex(
                cache_key,
                settings.IDEMPOTENCY_TTL_SECONDS,
                json.dumps(cache_data),
            )

            return JSONResponse(
                content=cache_data["body"],
                status_code=response.status_code,
            )

        return response
