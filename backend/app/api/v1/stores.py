"""
Rotas de lojas.

Referências:
- ARCHITECTURE.md §Backend Reference: api/v1/stores.py
- TECHNICAL_AUDIT.md §1.3: busca geoespacial otimizada
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.store import Store, StoreStatus
from app.schemas.product import StoreResponse
from app.core.security import get_current_user
from app.services.geo_service import GeoService

router = APIRouter()


@router.get("/", response_model=list[StoreResponse])
async def list_stores(
    lat: float = Query(None),
    lng: float = Query(None),
    radius_km: float = Query(10),
    db: AsyncSession = Depends(get_db),
):
    """Lista lojas ativas. Com lat/lng filtra por proximidade usando GeoService."""
    if lat is not None and lng is not None:
        geo = GeoService(db)
        nearby = await geo.find_stores_nearby(lat, lng, radius_km)
        # Return store objects for schema serialization
        from uuid import UUID
        store_ids = [UUID(s["id"]) for s in nearby]
        if not store_ids:
            return []
        stmt = select(Store).where(Store.id.in_(store_ids))
        result = await db.execute(stmt)
        return result.scalars().all()

    stmt = select(Store).where(Store.status == StoreStatus.ACTIVE).limit(50)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{store_id}", response_model=StoreResponse)
async def get_store(store_id: str, db: AsyncSession = Depends(get_db)):
    from uuid import UUID
    result = await db.execute(select(Store).where(Store.id == UUID(store_id)))
    store = result.scalar_one_or_none()
    if not store:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Store not found")
    return store
