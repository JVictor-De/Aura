"""
Geo Service: consultas geoespaciais com PostGIS e cache de geohash.

Referências:
- ARCHITECTURE.md §2.1: Geolocalização First
- ARCHITECTURE.md §ERD: STORES.delivery_area (Polygon), STORES.geohash
- TECHNICAL_AUDIT.md §1.3: busca geoespacial otimizada
"""

import logging
from uuid import UUID

from sqlalchemy import select, text, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.store import Store, StoreStatus

logger = logging.getLogger("zoe.geo_service")


class GeoService:
    """
    Serviço de geolocalização para busca de lojas por proximidade.

    No MVP usa cálculo de distância Haversine direto no PostgreSQL.
    Em produção, migrar para PostGIS ST_DWithin com índice GIST.
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def find_stores_nearby(
        self,
        lat: float,
        lng: float,
        radius_km: float = 10.0,
        limit: int = 50,
    ) -> list[dict]:
        """
        Busca lojas ativas dentro do raio especificado.

        MVP: Haversine formula em SQL puro (sem PostGIS extension).
        Produção: ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_m)

        ARCHITECTURE.md §2.1: "PostGIS para buscar lojas ativas cujo
        delivery_area contenha o ponto do usuário"
        """
        # Haversine em SQL (funciona sem PostGIS extension habilitada)
        haversine_sql = text("""
            SELECT id, name, cnpj, logo_url, lat, lng, rating, is_open,
                   (6371 * acos(
                       cos(radians(:lat)) * cos(radians(lat)) *
                       cos(radians(lng) - radians(:lng)) +
                       sin(radians(:lat)) * sin(radians(lat))
                   )) AS distance_km
            FROM stores
            WHERE status = 'active'
            HAVING distance_km <= :radius
            ORDER BY distance_km ASC
            LIMIT :limit
        """)

        # Fallback: usar filtro simples de bounding box + Haversine no Python
        stmt = (
            select(Store)
            .where(
                Store.status == StoreStatus.ACTIVE,
                Store.lat.between(lat - (radius_km / 111.0), lat + (radius_km / 111.0)),
                Store.lng.between(
                    lng - (radius_km / (111.0 * abs(lat) if lat != 0 else 111.0)),
                    lng + (radius_km / (111.0 * abs(lat) if lat != 0 else 111.0)),
                ),
            )
            .limit(limit)
        )

        result = await self.db.execute(stmt)
        stores = result.scalars().all()

        # Calcular distância real e filtrar
        nearby: list[dict] = []
        for store in stores:
            distance = self._haversine(lat, lng, store.lat, store.lng)
            if distance <= radius_km:
                nearby.append({
                    "id": str(store.id),
                    "name": store.name,
                    "logo_url": store.logo_url,
                    "lat": store.lat,
                    "lng": store.lng,
                    "rating": store.rating,
                    "is_open": store.is_open,
                    "distance_km": round(distance, 2),
                })

        nearby.sort(key=lambda s: s["distance_km"])
        return nearby

    @staticmethod
    def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        """Calcula distância em km entre dois pontos usando Haversine."""
        import math

        R = 6371  # raio da Terra em km
        dlat = math.radians(lat2 - lat1)
        dlng = math.radians(lng2 - lng1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(dlng / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    @staticmethod
    def compute_geohash(lat: float, lng: float, precision: int = 7) -> str:
        """
        Gera geohash simples para cache de proximidade.
        ARCHITECTURE.md §ERD: STORES.geohash indexed.
        """
        BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
        lat_range = [-90.0, 90.0]
        lng_range = [-180.0, 180.0]
        bits = [16, 8, 4, 2, 1]
        geohash_chars: list[str] = []
        ch = 0
        bit = 0
        even = True

        while len(geohash_chars) < precision:
            if even:
                mid = (lng_range[0] + lng_range[1]) / 2
                if lng >= mid:
                    ch |= bits[bit]
                    lng_range[0] = mid
                else:
                    lng_range[1] = mid
            else:
                mid = (lat_range[0] + lat_range[1]) / 2
                if lat >= mid:
                    ch |= bits[bit]
                    lat_range[0] = mid
                else:
                    lat_range[1] = mid
            even = not even
            if bit < 4:
                bit += 1
            else:
                geohash_chars.append(BASE32[ch])
                ch = 0
                bit = 0

        return "".join(geohash_chars)
