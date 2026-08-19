"""
Search Service: busca full-text com pg_trgm.

Referências:
- ARCHITECTURE.md §2.7: Busca e Filtros Avançados
- ARCHITECTURE.md §Índices: pg_trgm + GIN para busca full-text
- TECHNICAL_AUDIT.md §8: "Sem Elasticsearch (usar pg_trgm + GIN)"
"""

import logging

from sqlalchemy import select, text, or_, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.product import Product, ProductCategory
from app.models.store import Store, StoreStatus

logger = logging.getLogger("zoe.search_service")


class SearchService:
    """
    Busca full-text usando pg_trgm (trigram) do PostgreSQL.

    ARCHITECTURE.md §2.7: "Uso de pg_trgm + índice GIN no PostgreSQL
    para busca full-text performática sem dependência de Elasticsearch no MVP."

    Requer extensão habilitada:
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
    CREATE INDEX idx_stores_name_trgm ON stores USING GIN (name gin_trgm_ops);
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def search_products(
        self,
        query: str,
        store_id: str | None = None,
        category: str | None = None,
        size: str | None = None,
        color: str | None = None,
        min_price: float | None = None,
        max_price: float | None = None,
        brand: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[Product]:
        """
        Busca produtos com filtros avançados.

        ARCHITECTURE.md §2.7: "filtros por tamanho, cor, faixa de preço,
        marca e categoria. Autocomplete conforme o usuário digita."
        """
        stmt = select(Product).where(Product.is_active == True)

        if query:
            # pg_trgm similarity — fallback para ILIKE se extension não estiver habilitada
            stmt = stmt.where(
                or_(
                    Product.name.ilike(f"%{query}%"),
                    Product.brand.ilike(f"%{query}%"),
                    Product.description.ilike(f"%{query}%"),
                )
            )

        if store_id:
            from uuid import UUID
            stmt = stmt.where(Product.store_id == UUID(store_id))

        if category:
            stmt = stmt.where(Product.category == category)

        if brand:
            stmt = stmt.where(Product.brand.ilike(f"%{brand}%"))

        if min_price is not None:
            stmt = stmt.where(Product.base_price >= min_price)

        if max_price is not None:
            stmt = stmt.where(Product.base_price <= max_price)

        # Filtros de SKU (size, color) requerem join com sku_variants
        if size or color:
            from app.models.product import SkuVariant

            stmt = stmt.join(SkuVariant, Product.id == SkuVariant.product_id)

            if size:
                stmt = stmt.where(SkuVariant.size == size)
            if color:
                stmt = stmt.where(SkuVariant.color.ilike(f"%{color}%"))

            stmt = stmt.distinct()

        stmt = stmt.offset(offset).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def search_stores(
        self,
        query: str,
        limit: int = 20,
    ) -> list[Store]:
        """Busca lojas por nome."""
        stmt = (
            select(Store)
            .where(
                Store.status == StoreStatus.ACTIVE,
                Store.name.ilike(f"%{query}%"),
            )
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def autocomplete(
        self,
        query: str,
        limit: int = 10,
    ) -> dict:
        """
        Autocomplete para busca: retorna sugestões de produtos e lojas.
        ARCHITECTURE.md §2.7: "Autocomplete conforme o usuário digita."
        """
        if len(query) < 2:
            return {"products": [], "stores": []}

        products = await self.search_products(query, limit=limit)
        stores = await self.search_stores(query, limit=5)

        return {
            "products": [
                {"id": str(p.id), "name": p.name, "brand": p.brand}
                for p in products
            ],
            "stores": [
                {"id": str(s.id), "name": s.name}
                for s in stores
            ],
        }
