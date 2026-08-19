"""
Custom HTTP exceptions padronizadas.

Referências:
- TECHNICAL_AUDIT.md §6.2: Erros padronizados com code, message, details, request_id
- ARCHITECTURE.md §7: core/exceptions.py
"""

from fastapi import HTTPException, status


class ZoeHTTPException(HTTPException):
    """Base para exceções HTTP padronizadas do Zoe."""

    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: dict | None = None,
    ):
        super().__init__(
            status_code=status_code,
            detail={
                "code": code,
                "message": message,
                "details": details or {},
            },
        )


class StockUnavailableException(ZoeHTTPException):
    def __init__(self, sku: str, available: int = 0):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="STOCK_UNAVAILABLE",
            message="Estoque insuficiente para a variação selecionada.",
            details={"sku": sku, "available": available},
        )


class ReservationExpiredException(ZoeHTTPException):
    def __init__(self, reservation_id: str):
        super().__init__(
            status_code=status.HTTP_410_GONE,
            code="RESERVATION_EXPIRED",
            message="Reserva de estoque expirada. Tente novamente.",
            details={"reservation_id": reservation_id},
        )


class StoreConflictException(ZoeHTTPException):
    def __init__(self, current_store: str, new_store: str):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="CART_STORE_CONFLICT",
            message="Carrinho contém itens de outra loja.",
            details={
                "current_store": current_store,
                "new_store": new_store,
            },
        )


class PaymentFailedException(ZoeHTTPException):
    def __init__(self, order_id: str):
        super().__init__(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            code="PAYMENT_FAILED",
            message="Pagamento falhou. Reservas liberadas.",
            details={"order_id": order_id},
        )


class IdempotencyConflictException(ZoeHTTPException):
    def __init__(self, key: str):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="IDEMPOTENCY_CONFLICT",
            message="Operação com esta chave já está em processamento.",
            details={"idempotency_key": key},
        )


class TenantAccessDeniedException(ZoeHTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            code="TENANT_ACCESS_DENIED",
            message="Acesso negado a recursos de outra loja.",
        )


class ResourceNotFoundException(ZoeHTTPException):
    def __init__(self, resource: str, identifier: str):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            code="RESOURCE_NOT_FOUND",
            message=f"{resource} não encontrado.",
            details={"resource": resource, "identifier": identifier},
        )


class InvalidCouponException(ZoeHTTPException):
    def __init__(self, reason: str):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            code="INVALID_COUPON",
            message=reason,
        )


class RateLimitExceededException(ZoeHTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            code="RATE_LIMIT_EXCEEDED",
            message="Muitas requisições. Tente novamente em alguns minutos.",
        )
