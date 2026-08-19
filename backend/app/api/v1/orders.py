"""
Rotas de pedidos com idempotência e split multi-loja.

Referências:
- ARCHITECTURE.md §Contratos de API: POST /orders, GET /orders/{id}
- ARCHITECTURE.md §Headers Obrigatórios: X-Idempotency-Key
- ARCHITECTURE.md §Checkout Crítico: fluxo completo com stock lock
- ARCHITECTURE.md §Notas de Modelagem: ORDER_SHIPMENTS por loja
"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user, require_role
from app.core.redis import get_redis
from app.models.user import User, UserRole
from app.models.order import Order, OrderShipment, OrderItem, OrderStatus
from app.models.product import SkuVariant
from app.schemas.order import (
    CreateOrderRequest, CreateOrderResponse, ShipmentResponse,
    OrderResponse,
)
from app.services.stock_service import StockReservationService
from app.services.payment_service import PaymentService

router = APIRouter()


@router.post("/", response_model=CreateOrderResponse)
async def create_order(
    data: CreateOrderRequest,
    x_idempotency_key: str = Header(..., alias="X-Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Cria pedido com split por loja e reserva de estoque.
    ARCHITECTURE.md §Checkout Crítico:
    1. Validação de preços
    2. Reserva de estoque (STOCK_RESERVATIONS)
    3. Criação ORDER + ORDER_SHIPMENTS + ORDER_ITEMS
    4. Intent de pagamento
    """
    redis = get_redis()
    stock_service = StockReservationService(db, redis)
    payment_service = PaymentService(db, redis)

    reservation_ids: list[str] = []
    items_by_store: dict[uuid.UUID, list] = {}

    # 1. Validar SKUs e agrupar por loja
    for item_req in data.items:
        result = await db.execute(
            select(SkuVariant).where(SkuVariant.sku == item_req.sku)
        )
        variant = result.scalar_one_or_none()
        if not variant:
            raise HTTPException(status_code=404, detail=f"SKU {item_req.sku} not found")

        # 2. Reservar estoque (TECHNICAL_AUDIT §1.2)
        reservation = await stock_service.reserve_stock(
            sku=item_req.sku,
            quantity=item_req.quantity,
            user_id=str(current_user.id),
            session_id=x_idempotency_key,
        )
        reservation_ids.append(reservation["reservation_id"])

        product = variant.product
        store_id = product.store_id

        if store_id not in items_by_store:
            items_by_store[store_id] = []
        items_by_store[store_id].append({
            "variant": variant,
            "product": product,
            "quantity": item_req.quantity,
        })

    # 3. Calcular totais
    subtotal = sum(
        item["variant"].price * item["quantity"]
        for items in items_by_store.values()
        for item in items
    )

    # 4. Criar ORDER
    order = Order(
        user_id=current_user.id,
        status=OrderStatus.PENDING,
        subtotal=subtotal,
        total=subtotal,
        idempotency_key=x_idempotency_key,
        delivery_address_id=data.address_id,
    )
    db.add(order)
    await db.flush()

    # 5. Criar ORDER_SHIPMENTS por loja (ARCHITECTURE.md §Notas de Modelagem)
    shipments_response: list[ShipmentResponse] = []
    for store_id, items in items_by_store.items():
        shipment = OrderShipment(
            order_id=order.id,
            store_id=store_id,
        )
        db.add(shipment)
        await db.flush()

        # 6. Criar ORDER_ITEMS vinculados ao shipment
        for item_data in items:
            oi = OrderItem(
                shipment_id=shipment.id,
                product_id=item_data["product"].id,
                sku_variant_id=item_data["variant"].id,
                quantity=item_data["quantity"],
                unit_price=item_data["variant"].price,
                total_price=item_data["variant"].price * item_data["quantity"],
            )
            db.add(oi)

        shipments_response.append(ShipmentResponse(
            shipment_id=shipment.id,
            store_id=store_id,
            delivery_fee=0,
            status=shipment.status.value,
        ))

    # 7. Criar intent de pagamento (ARCHITECTURE.md §Checkout Crítico §4)
    payment = await payment_service.create_payment(
        order_id=order.id,
        amount=subtotal,
        provider=data.payment_method,
        idempotency_key=f"pay_{x_idempotency_key}",
        reservation_ids=reservation_ids,
    )

    return CreateOrderResponse(
        order_id=order.id,
        shipments=shipments_response,
        payment_id=payment.id,
        payment_status=payment.status,
    )


@router.get("/", response_model=list[OrderResponse])
async def list_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista pedidos do usuário. Lojistas veem apenas pedidos da sua loja
    (ARCHITECTURE.md §Auth: filtros de pedido por loja).
    """
    if current_user.role == UserRole.MERCHANT and current_user.store_id:
        # RBAC: lojista só vê pedidos com shipments da sua loja
        stmt = (
            select(Order)
            .join(OrderShipment, Order.id == OrderShipment.order_id)
            .where(OrderShipment.store_id == current_user.store_id)
            .distinct()
        )
    else:
        stmt = select(Order).where(Order.user_id == current_user.id)

    result = await db.execute(stmt.order_by(Order.created_at.desc()))
    return result.scalars().all()


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from uuid import UUID
    result = await db.execute(select(Order).where(Order.id == UUID(order_id)))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # RBAC: verificar acesso
    if current_user.role == UserRole.CUSTOMER and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    if current_user.role == UserRole.MERCHANT:
        has_shipment = any(s.store_id == current_user.store_id for s in order.shipments)
        if not has_shipment:
            raise HTTPException(status_code=403, detail="Access denied")

    return order
