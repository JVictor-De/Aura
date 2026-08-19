"""
Exception Handler global que garante reversão de locks de estoque.

Referências:
- TECHNICAL_AUDIT.md §1.2 Sincronização de Estoque:
  "falhas em transações de pagamento sempre revertam o lock de estoque
   (sem deixar o inventário inconsistente)"
- ARCHITECTURE.md §Checkout Crítico §8:
  "Falhas: se webhook não chegar, job de reconciliação consulta o gateway"

Estratégia:
- PaymentFailedError → libera todas as STOCK_RESERVATIONS associadas
- StockLockError → retorna 409 Conflict com info de disponibilidade
- Qualquer exceção não tratada → loga e retorna 500 sem vazar detalhes
"""

import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger("zoe.exception_handler")


class PaymentFailedError(Exception):
    """Falha na transação de pagamento – estoque deve ser revertido."""
    def __init__(self, order_id: str, reservation_ids: list[str] | None = None):
        self.order_id = order_id
        self.reservation_ids = reservation_ids or []


class StockLockError(Exception):
    """Não foi possível adquirir lock de estoque (row locked ou esgotado)."""
    def __init__(self, sku: str, available: int = 0):
        self.sku = sku
        self.available = available


class ReservationExpiredError(Exception):
    """Reserva expirou antes da confirmação de pagamento."""
    def __init__(self, reservation_id: str):
        self.reservation_id = reservation_id


def register_exception_handlers(app: FastAPI):
    @app.exception_handler(PaymentFailedError)
    async def payment_failed_handler(request: Request, exc: PaymentFailedError):
        """
        TECHNICAL_AUDIT §1.2: reverte lock de estoque quando pagamento falha.
        A liberação real ocorre via StockReservationService.release_reservation()
        invocado no service layer. Aqui apenas devolvemos resposta amigável.
        """
        logger.error(
            "Payment failed for order %s – stock reservations %s will be released",
            exc.order_id,
            exc.reservation_ids,
        )
        return JSONResponse(
            status_code=402,
            content={
                "detail": "Payment failed. Stock reservations have been released.",
                "order_id": exc.order_id,
            },
        )

    @app.exception_handler(StockLockError)
    async def stock_lock_handler(request: Request, exc: StockLockError):
        """TECHNICAL_AUDIT §1.2: 409 Conflict quando SKU já está locked ou esgotado."""
        return JSONResponse(
            status_code=409,
            content={
                "detail": f"Stock unavailable for SKU {exc.sku}",
                "available": exc.available,
            },
        )

    @app.exception_handler(ReservationExpiredError)
    async def reservation_expired_handler(request: Request, exc: ReservationExpiredError):
        return JSONResponse(
            status_code=410,
            content={
                "detail": "Stock reservation expired. Please try again.",
                "reservation_id": exc.reservation_id,
            },
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"},
        )
