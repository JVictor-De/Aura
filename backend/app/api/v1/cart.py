"""
Rotas do carrinho com single-store lock e controle de reservas.

Referências:
- ARCHITECTURE.md §8.2: Single-store lock no MVP
- ARCHITECTURE.md §ERD: CART_SESSIONS, CART_ITEMS
- TECHNICAL_AUDIT.md §2.4: confirmação ao trocar de loja
- TECHNICAL_AUDIT.md §5.2: fluxo CartStoreConflict
"""

from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.security import get_current_user
from app.core.redis import get_redis
from app.models.user import User
from app.models.store import Store
from app.models.product import SkuVariant
from app.models.cart import CartSession, CartItem, CartSessionStatus
from app.schemas.cart import (
    AddToCartRequest,
    UpdateCartItemRequest,
    CartItemResponse,
    CartSessionResponse,
    CartStoreConflictResponse,
    ClearCartAndAddRequest,
)
from app.services.stock_service import StockReservationService

router = APIRouter()


async def _get_active_cart(
    user_id: UUID, db: AsyncSession
) -> CartSession | None:
    """Retorna sessão de carrinho ativa do usuário."""
    result = await db.execute(
        select(CartSession)
        .where(
            CartSession.user_id == user_id,
            CartSession.status == CartSessionStatus.ACTIVE,
        )
        .order_by(CartSession.created_at.desc())
    )
    return result.scalar_one_or_none()


async def _build_cart_response(
    cart: CartSession, db: AsyncSession
) -> CartSessionResponse:
    """Constrói resposta do carrinho com dados enriquecidos."""
    items_response: list[CartItemResponse] = []
    subtotal = 0.0

    for item in cart.items:
        variant = item.sku_variant
        product = variant.product if variant else None
        total = float(item.unit_price) * item.quantity
        subtotal += total

        items_response.append(CartItemResponse(
            id=item.id,
            sku_variant_id=item.sku_variant_id,
            sku=variant.sku if variant else "",
            product_name=product.name if product else "",
            size=variant.size if variant else "",
            color=variant.color if variant else "",
            quantity=item.quantity,
            unit_price=float(item.unit_price),
            total_price=total,
            image_url=variant.image_url if variant else None,
        ))

    store = cart.store

    return CartSessionResponse(
        id=cart.id,
        store_id=cart.store_id,
        store_name=store.name if store else "",
        status=cart.status.value,
        items=items_response,
        subtotal=subtotal,
        item_count=sum(i.quantity for i in cart.items),
        created_at=cart.created_at,
    )


@router.get("/", response_model=CartSessionResponse | None)
async def get_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retorna o carrinho ativo do usuário."""
    cart = await _get_active_cart(current_user.id, db)
    if not cart:
        return None
    return await _build_cart_response(cart, db)


@router.post("/items", response_model=CartSessionResponse, status_code=201)
async def add_to_cart(
    data: AddToCartRequest,
    x_idempotency_key: str | None = Header(None, alias="X-Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Adiciona item ao carrinho com single-store lock.

    ARCHITECTURE.md §8.2: se carrinho existe para outra loja, retorna 409
    com CartStoreConflictResponse.
    """
    # Validar SKU
    result = await db.execute(
        select(SkuVariant).where(SkuVariant.sku == data.sku)
    )
    variant = result.scalar_one_or_none()
    if not variant:
        raise HTTPException(status_code=404, detail=f"SKU {data.sku} not found")

    if not variant.is_available or variant.stock_quantity < data.quantity:
        raise HTTPException(
            status_code=409,
            detail={"code": "STOCK_UNAVAILABLE", "available": variant.stock_quantity},
        )

    # Verificar single-store lock (ARCHITECTURE.md §8.2)
    cart = await _get_active_cart(current_user.id, db)

    if cart and cart.store_id != data.store_id:
        # Conflito de loja — exigir confirmação (TECHNICAL_AUDIT §5.2)
        store_current = await db.get(Store, cart.store_id)
        store_new = await db.get(Store, data.store_id)
        raise HTTPException(
            status_code=409,
            detail=CartStoreConflictResponse(
                current_store_id=cart.store_id,
                current_store_name=store_current.name if store_current else "",
                new_store_id=data.store_id,
                new_store_name=store_new.name if store_new else "",
            ).model_dump(mode="json"),
        )

    # Criar sessão se não existe
    if not cart:
        cart = CartSession(
            user_id=current_user.id,
            store_id=data.store_id,
        )
        db.add(cart)
        await db.flush()

    # Verificar se SKU já está no carrinho
    existing_item = next(
        (i for i in cart.items if i.sku_variant_id == variant.id), None
    )

    if existing_item:
        existing_item.quantity += data.quantity
    else:
        cart_item = CartItem(
            cart_session_id=cart.id,
            sku_variant_id=variant.id,
            quantity=data.quantity,
            unit_price=variant.price,
        )
        db.add(cart_item)

    await db.flush()

    # Refresh cart
    await db.refresh(cart, ["items"])
    return await _build_cart_response(cart, db)


@router.post("/clear-and-add", response_model=CartSessionResponse)
async def clear_cart_and_add(
    data: ClearCartAndAddRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Limpa carrinho atual e adiciona item de nova loja.
    TECHNICAL_AUDIT §5.2: confirmação do usuário já recebida.
    """
    cart = await _get_active_cart(current_user.id, db)
    if cart:
        cart.status = CartSessionStatus.ABANDONED
        await db.flush()

    # Validar SKU
    result = await db.execute(
        select(SkuVariant).where(SkuVariant.sku == data.sku)
    )
    variant = result.scalar_one_or_none()
    if not variant:
        raise HTTPException(status_code=404, detail=f"SKU {data.sku} not found")

    # Criar nova sessão
    new_cart = CartSession(
        user_id=current_user.id,
        store_id=data.new_store_id,
    )
    db.add(new_cart)
    await db.flush()

    cart_item = CartItem(
        cart_session_id=new_cart.id,
        sku_variant_id=variant.id,
        quantity=data.quantity,
        unit_price=variant.price,
    )
    db.add(cart_item)
    await db.flush()

    await db.refresh(new_cart, ["items"])
    return await _build_cart_response(new_cart, db)


@router.patch("/items/{item_id}", response_model=CartSessionResponse)
async def update_cart_item(
    item_id: UUID,
    data: UpdateCartItemRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Atualiza quantidade de um item no carrinho."""
    cart = await _get_active_cart(current_user.id, db)
    if not cart:
        raise HTTPException(status_code=404, detail="No active cart")

    item = next((i for i in cart.items if i.id == item_id), None)
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    # Validar estoque
    variant = item.sku_variant
    if variant and variant.stock_quantity < data.quantity:
        raise HTTPException(
            status_code=409,
            detail={"code": "STOCK_UNAVAILABLE", "available": variant.stock_quantity},
        )

    item.quantity = data.quantity
    await db.flush()

    await db.refresh(cart, ["items"])
    return await _build_cart_response(cart, db)


@router.delete("/items/{item_id}", response_model=CartSessionResponse)
async def remove_cart_item(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove item do carrinho."""
    cart = await _get_active_cart(current_user.id, db)
    if not cart:
        raise HTTPException(status_code=404, detail="No active cart")

    item = next((i for i in cart.items if i.id == item_id), None)
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    await db.delete(item)
    await db.flush()

    await db.refresh(cart, ["items"])

    # Se carrinho vazio, abandonar sessão
    if not cart.items:
        cart.status = CartSessionStatus.ABANDONED

    return await _build_cart_response(cart, db)


@router.delete("/")
async def clear_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Limpa o carrinho ativo."""
    cart = await _get_active_cart(current_user.id, db)
    if cart:
        cart.status = CartSessionStatus.ABANDONED
    return {"detail": "Cart cleared"}


@router.post("/validate-prices")
async def validate_cart_prices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Revalida preços do carrinho contra o servidor.
    TECHNICAL_AUDIT.md §R6: preço final backend-driven.
    """
    cart = await _get_active_cart(current_user.id, db)
    if not cart:
        raise HTTPException(status_code=404, detail="No active cart")

    changes: list[dict] = []
    for item in cart.items:
        variant = item.sku_variant
        if variant and float(item.unit_price) != variant.price:
            changes.append({
                "sku": variant.sku,
                "old_price": float(item.unit_price),
                "new_price": variant.price,
            })
            item.unit_price = variant.price

    return {
        "prices_valid": len(changes) == 0,
        "changes": changes,
    }
