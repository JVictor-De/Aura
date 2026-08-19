# 🏗️ Arquitetura do Sistema Zoe (Review & Prod-Ready)

## 1. Visão Geral
O **Zoe** é um ecossistema de delivery de moda composto por:
- **Zoe App** (Mobile/Web) — Aplicativo para clientes (Flutter).
- **Zoe Portal** (Web) — Dashboard Administrativo e para Lojistas (Flutter Web).
- **Zoe Core API** — Backend centralizado gerenciando pedidos, pagamentos, estoque, geolocalização e logística reversa (Python / FastAPI / PostgreSQL / PostGIS / Redis).

---

## 2. ✨ Mapeamento de Funcionalidades Essenciais (On-Demand Delivery)

Para proporcionar uma UX comparável a "Super Apps" de delivery (iFood, Zé Delivery), mas adaptada ao cenário de moda (Fashion), a arquitetura engloba os seguintes módulos:

### 2.1 Geolocalização First (Multi-Endereços)
- **Como funciona:** O usuário deve informar a localização (GPS ou Manual) *antes* de carregar a Home do catálogo, o que aciona o **PostGIS** para buscar lojas ativas cujo `delivery_area` (polígono) contenha o ponto do usuário.
- **Impacto na Arquitetura:** O estado de inicialização exige um `AddressCubit` que filtra globalmente os *requests* das vitrines por coordenada.

### 2.2 Cupons e Promos (Promotion Engine)
- **Como funciona:** Aplicabilidade de cupons no Checkout. O modelo valida regras como compra mínima, cupom por loja específica, limites de uso e validade.
- **Impacto na Arquitetura:** Cálculo do carrinho passa a ser *Backend-Driven*. O frontend confia na resposta da API (`total_amount`, `discount_amount`) para evitar fraudes client-side.

### 2.3 Rastreamento em Tempo Real (Live Tracking) e Chat
- **Como funciona:** Usuário acompanha o status "Separando → A Caminho → Entregue", com mapa ao vivo caso a loja possua frota própria conectada (ou integração com provedores logísticos de last-mile). Chat embedado permite falar direto com a loja.
- **Impacto na Arquitetura:** Uso de **WebSockets / Server-Sent Events (SSE)** no FastAPI. Fallback para polling HTTP a cada 30s se conexão WS cair.

### 2.4 Logística Reversa Fácil (RMA — Devoluções/Trocas)
- **Como funciona:** Diferente de comida, roupas não servem ou o caimento não agrada. A tela de pedidos permite, em até 7 dias, um *flow* de um clique para "Solicitar Devolução" por item individual.
- **Impacto na Arquitetura:** Criação das entidades `RMA_REQUESTS` e `RMA_ITEMS`, amarradas a `ORDER_ITEMS`. Estorno parcial via `PaymentService`.

### 2.5 Wishlist (Favoritos) e Social Proof (Reviews)
- **Como funciona:** Botão de coração (❤️) para curtir um look. Após a entrega, solicitação de duplo rate: Nota da Entrega (Serviço) e Nota da Peça (Caimento, Tecido).
- **Impacto na Arquitetura:** Criação de *Materialized Views* no Postgres ou consolidação em Redis para a média de estrelas (Ratings) visando não onerar consultas pesadas nas lojas.

### 2.6 Notificações (Push + In-App)
- **Como funciona:** O usuário recebe push via **Firebase Cloud Messaging (FCM)** para atualizações de status do pedido ("Pedido aceito", "Saiu para entrega", "Entregue"), promoções e lembretes de carrinho abandonado. Se o push falhar (permissão negada), o app mantém um **Notification Center interno** com badge no ícone.
- **Impacto na Arquitetura:** Serviço `notification_service.py` no backend. Feature `notifications/` no Flutter com `NotificationCubit`.

### 2.7 Busca e Filtros Avançados
- **Como funciona:** Busca textual de produtos/lojas com filtros por tamanho, cor, faixa de preço, marca e categoria. Autocomplete conforme o usuário digita.
- **Impacto na Arquitetura:** Uso de `pg_trgm` (trigram) + índice GIN no PostgreSQL para busca full-text performática sem dependência de Elasticsearch no MVP.

---

## 3. 🚨 Gap Analysis & Design Review Inicial (Refatorado para Produção)

### 3.1 Integridade do Multi-tenant (Row-Level Security)
Utilizamos **RLS (Row-Level Security) nativa do PostgreSQL**. Injetamos o `tenant_id` (`store_id`) na `Transaction Session` via JWT antes de cada transação, eliminando o risco do desenvolvedor esquecer cláusulas `WHERE` no ORM e acabar vazando dados entre lojistas.

### 3.2 Validação do Fluxo de Dados e Imagens (CDN & WebP)
Imagens em alta-resolução destroem o tempo de resposta da API Padrão. A API apenas entrega URLs (Signed ou Públicas) que apontam para uma **CDN (Edge Network)**. No app, o pacote `cached_network_image` retém as fotos reduzidas em cache agressivo (*blurhash* fallback).

### 3.3 Gestão de Estado (Anti-Death / OOM Mitigation)
Se o SO (iOS/Android) fechar o aplicativo do Zoe por falta de RAM porque o usuário foi checar o WhatsApp, o carrinho é recuperado integralmente através do **HydratedBloc** sincronizado ao banco off-line local **Drift (SQLite)**.

---

## 4. 🗄️ Arquitetura de Banco de Dados (ERD Completo e Revisado)

Este diagrama representa o modelo relacional final. Inclui todas as entidades do sistema: carrinho, estoque, pagamento, cupons, rastreio, devoluções, favoritos e avaliações.

```mermaid
erDiagram
    USERS ||--o{ ADDRESSES : "possui"
    USERS ||--o{ ORDERS : "realiza"
    USERS ||--o{ REVIEWS : "escreve"
    USERS ||--o{ WISHLISTS : "favorita"
    USERS ||--o{ CART_SESSIONS : "mantém"
    USERS ||--o{ NOTIFICATION_TOKENS : "registra"
    STORES ||--o{ PRODUCTS : "gerencia"
    STORES ||--o{ ORDERS : "cumpre"
    STORES ||--o{ COUPONS : "oferece"
    PRODUCTS ||--o{ SKU_VARIANTS : "tem variações"
    SKU_VARIANTS ||--o{ STOCK_RESERVATIONS : "reservado por"
    CART_SESSIONS ||--o{ CART_ITEMS : "contém"
    CART_ITEMS }|--|| SKU_VARIANTS : "referencia"
    ORDERS ||--o{ ORDER_SHIPMENTS : "dividido em"
    ORDER_SHIPMENTS ||--o{ ORDER_ITEMS : "contém"
    ORDER_ITEMS }|--|| SKU_VARIANTS : "referencia"
    ORDER_ITEMS ||--o{ RMA_ITEMS : "pode devolver"
    ORDERS ||--o{ PAYMENTS : "pago via"
    PAYMENTS ||--o{ PAYMENT_EVENTS : "registra evento"
    ORDERS ||--o| DELIVERY_TRACKING : "rastreado por"
    ORDERS ||--o{ RMA_REQUESTS : "solicitação de troca"
    RMA_REQUESTS ||--o{ RMA_ITEMS : "inclui itens"
    ORDERS ||--o| APPLIED_COUPONS : "desconto aplicado"
    COUPONS ||--o{ APPLIED_COUPONS : "usado em"
    PRODUCTS ||--o{ REVIEWS : "avaliado em"

    USERS {
      uuid id PK
      string email "UNIQUE, indexed"
      string password_hash
      string name
      string phone
      string avatar_url "CDN"
      string role "ENUM [customer, merchant, admin]"
      string auth_provider "ENUM [email, google, apple]"
      timestamptz created_at
      timestamptz updated_at
    }

    ADDRESSES {
      uuid id PK
      uuid user_id FK
      string label "(Casa, Trabalho)"
      string street
      string number
      string complement
      string neighborhood
      string city
      string state
      string zip_code
      geometry coords "PostGIS Point"
      boolean is_default
      timestamptz created_at
    }

    STORES {
      uuid id PK
      string name
      string cnpj "UNIQUE"
      string phone
      string logo_url "CDN"
      string description
      geometry location "PostGIS Point (centro)"
      geometry delivery_area "PostGIS Polygon"
      string geohash "indexed (B-tree, para cache)"
      decimal rating_avg "cache consolidado"
      boolean is_active
      timestamptz created_at
      timestamptz updated_at
    }

    PRODUCTS {
      uuid id PK
      uuid store_id FK "RLS Enforced, indexed"
      string name
      string description
      string category "indexed"
      string brand
      string hires_image_url "CDN ref"
      boolean is_active
      timestamptz created_at
      timestamptz updated_at
    }

    SKU_VARIANTS {
      uuid id PK
      uuid product_id FK "indexed"
      string sku "UNIQUE"
      string size
      string color
      decimal price
      decimal compare_at_price "preço anterior (riscado)"
      int stock_quantity
      decimal weight_kg
      boolean is_active
      timestamptz updated_at
    }

    STOCK_RESERVATIONS {
      uuid id PK
      uuid sku_variant_id FK
      uuid user_id FK
      uuid cart_session_id FK
      int quantity
      timestamptz expires_at "TTL 15min"
      string status "ENUM [active, confirmed, expired, released]"
      timestamptz created_at
    }

    CART_SESSIONS {
      uuid id PK
      uuid user_id FK
      uuid store_id FK "single-store lock"
      string status "ENUM [active, checked_out, abandoned]"
      timestamptz created_at
      timestamptz updated_at
    }

    CART_ITEMS {
      uuid id PK
      uuid cart_session_id FK
      uuid sku_variant_id FK
      int quantity
      decimal unit_price "snapshot no momento de add"
      timestamptz created_at
    }

    ORDERS {
      uuid id PK
      uuid user_id FK
      uuid store_id FK "RLS Enforced"
      uuid delivery_address_id FK
      string status "ENUM [pending, paid, preparing, out_for_delivery, delivered, cancelled]"
      decimal subtotal
      decimal delivery_fee
      decimal discount_amount
      decimal total_amount
      string idempotency_key "UNIQUE"
      timestamptz created_at
      timestamptz updated_at
    }

    ORDER_SHIPMENTS {
      uuid id PK
      uuid order_id FK
      uuid store_id FK
      string status "ENUM [pending, separated, dispatched, delivered]"
      decimal shipping_cost
      string tracking_code
      timestamptz estimated_delivery
      timestamptz created_at
    }

    ORDER_ITEMS {
      uuid id PK
      uuid order_shipment_id FK
      uuid sku_variant_id FK
      int quantity
      decimal unit_price "snapshot"
      decimal total_price
    }

    PAYMENTS {
      uuid id PK
      uuid order_id FK
      string gateway "ENUM [stripe, mercadopago, pix]"
      string method "ENUM [credit_card, debit_card, pix, boleto]"
      decimal amount
      string status "ENUM [pending, approved, failed, refunded, partial_refund]"
      string idempotency_key "UNIQUE"
      string gateway_transaction_id
      timestamptz created_at
    }

    PAYMENT_EVENTS {
      uuid id PK
      uuid payment_id FK
      string event_type "ENUM [created, approved, failed, refunded, chargeback]"
      jsonb raw_payload "webhook payload completo"
      timestamptz received_at
    }

    COUPONS {
      uuid id PK
      uuid store_id FK "NULL = global"
      string code "UNIQUE"
      decimal discount_value
      string discount_type "ENUM [fixed, percentage]"
      decimal min_purchase
      int max_uses
      int current_uses "default 0"
      int max_uses_per_user
      timestamptz valid_from
      timestamptz valid_until
      boolean is_active
      timestamptz created_at
    }

    APPLIED_COUPONS {
      uuid id PK
      uuid order_id FK
      uuid coupon_id FK
      uuid user_id FK
      decimal discount_applied
      timestamptz applied_at
    }

    DELIVERY_TRACKING {
      uuid id PK
      uuid order_id FK "UNIQUE"
      string driver_name
      string driver_phone
      geometry current_location "PostGIS Point"
      string status "ENUM [assigned, picking_up, en_route, arriving, delivered]"
      timestamptz estimated_arrival
      timestamptz updated_at
    }

    RMA_REQUESTS {
      uuid id PK
      uuid order_id FK
      uuid user_id FK
      string status "ENUM [requested, approved, rejected, refunded, exchanged]"
      string resolution_type "ENUM [refund, exchange]"
      timestamptz requested_at
      timestamptz resolved_at
    }

    RMA_ITEMS {
      uuid id PK
      uuid rma_request_id FK
      uuid order_item_id FK
      int quantity
      string reason "ENUM [wrong_size, defect, changed_mind, wrong_item]"
      string condition "ENUM [unopened, used, damaged]"
    }

    WISHLISTS {
      uuid id PK
      uuid user_id FK
      uuid product_id FK
      timestamptz created_at
    }

    REVIEWS {
      uuid id PK
      uuid user_id FK
      uuid product_id FK
      uuid order_id FK "garante que comprou"
      int rating_product "1-5"
      int rating_delivery "1-5"
      string comment
      boolean is_visible "moderação"
      timestamptz created_at
    }

    NOTIFICATION_TOKENS {
      uuid id PK
      uuid user_id FK
      string token "FCM device token"
      string platform "ENUM [ios, android, web]"
      boolean is_active
      timestamptz created_at
    }
```

### Índices recomendados
```sql
-- Geolocalização
CREATE INDEX idx_stores_delivery_area_gist ON stores USING GIST (delivery_area);
CREATE INDEX idx_stores_geohash ON stores (geohash);
CREATE INDEX idx_addresses_coords_gist ON addresses USING GIST (coords);

-- Busca textual
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
CREATE INDEX idx_stores_name_trgm ON stores USING GIN (name gin_trgm_ops);

-- Queries frequentes
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_store_id ON orders (store_id);
CREATE INDEX idx_order_items_shipment ON order_items (order_shipment_id);
CREATE INDEX idx_sku_product ON sku_variants (product_id);
CREATE INDEX idx_products_store ON products (store_id);
CREATE INDEX idx_stock_reservations_sku ON stock_reservations (sku_variant_id) WHERE status = 'active';
CREATE INDEX idx_wishlists_user ON wishlists (user_id);
CREATE INDEX idx_reviews_product ON reviews (product_id);
```

---

## 5. 📁 Árvore de Diretórios: Flutter App (Cliente)

```text
apps/zoe_app/lib/
├── main.dart
├── app.dart                      # MaterialApp, GoRouter, BlocProviders
├── injection.dart                # GetIt + Injectable
├── core/
│   ├── config/
│   │   ├── app_config.dart       # Flavors (dev/stg/prod)
│   │   ├── env.dart              # Variáveis de ambiente
│   │   └── routes.dart           # Rotas nomeadas
│   ├── network/
│   │   ├── api_client.dart       # Dio singleton
│   │   ├── network_info.dart     # Connectivity check
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       ├── idempotency_interceptor.dart
│   │       ├── cache_interceptor.dart
│   │       └── logging_interceptor.dart
│   ├── storage/
│   │   ├── drift_database.dart   # Drift (SQLite) para offline
│   │   └── secure_storage.dart   # Tokens JWT
│   ├── permissions/
│   │   ├── location_handler.dart
│   │   └── notification_handler.dart
│   ├── theme/
│   │   ├── zoe_colors.dart
│   │   ├── zoe_typography.dart
│   │   ├── zoe_spacing.dart
│   │   └── zoe_theme.dart
│   └── error/
│       ├── exceptions.dart
│       └── failures.dart
│
├── domain/
│   ├── entities/                 # Freezed immutable objects
│   │   ├── user.dart
│   │   ├── address.dart
│   │   ├── store.dart
│   │   ├── product.dart
│   │   ├── sku_variant.dart
│   │   ├── cart.dart
│   │   ├── order.dart
│   │   ├── tracking.dart
│   │   ├── review.dart
│   │   └── rma_request.dart
│   └── services/                 # Interfaces coesas
│       ├── i_auth_service.dart
│       ├── i_catalog_service.dart
│       ├── i_cart_service.dart
│       ├── i_order_service.dart
│       └── i_notification_service.dart
│
├── data/
│   ├── dtos/                     # JSON serializable
│   ├── mappers/                  # DTO <-> Entity
│   └── repositories/
│       ├── auth_repository.dart
│       ├── catalog_repository.dart
│       ├── cart_repository.dart  # API + Drift fallback
│       ├── order_repository.dart
│       └── review_repository.dart
│
└── presentation/
    ├── app_router.dart           # GoRouter (deep links, guards)
    ├── common/                   # Widgets reutilizáveis, skeletons
    │   ├── zoe_button.dart
    │   ├── zoe_cached_image.dart
    │   └── skeleton/
    └── features/
        ├── splash/
        ├── onboarding/
        ├── location_onboarding/  # GPS/endereço obrigatório antes de home
        ├── authentication/
        │   ├── cubit/
        │   └── ui/
        ├── home/                 # Feed principal
        ├── store_catalog/        # Vitrines + busca + filtros
        │   ├── cubit/
        │   └── ui/
        ├── product_details/      # Hero transition + variantes
        ├── search/               # Busca full-text + autocomplete
        ├── wishlist/             # Favoritos
        ├── checkout_cart/        # Carrinho + cupons + reserva
        │   ├── cubit/cart_cubit.dart    # HydratedMixin + mutex
        │   ├── cubit/checkout_cubit.dart
        │   └── ui/
        ├── order_history/        # Histórico + reorder
        ├── active_tracking/      # Mapa + WS + chat
        ├── returns_rma/          # Devolução por item
        ├── profile/              # Dados pessoais + endereços
        ├── payment_methods/      # Cartões salvos
        └── notifications/        # Central de notificações in-app
```

---

## 6. 📁 Árvore de Diretórios: Dashboard Web (Zoe Portal)

```text
apps/zoe_portal/lib/
├── main.dart
├── app.dart
├── injection.dart
├── core/
│   ├── config/
│   ├── network/                  # Dio com auth interceptor merchant/admin
│   ├── theme/portal_theme.dart
│   └── guards/                   # RBAC route guards (merchant vs admin)
│
├── domain/
│   ├── entities/
│   └── services/
│
├── data/
│   ├── dtos/
│   └── repositories/
│
└── presentation/
    ├── layout/                   # Shell layout (sidebar + topbar)
    ├── common/
    └── features/
        ├── login/                # Auth merchant/admin
        ├── dashboard/            # KPIs: vendas, pedidos, ticket médio
        ├── orders/               # Pedidos em tempo real (WebSocket)
        │   ├── cubit/
        │   └── ui/
        ├── inventory/            # Gestão de SKUs, estoque, preços
        │   ├── cubit/
        │   └── ui/
        ├── products/             # CRUD de produtos (upload CDN)
        ├── returns_rma/          # Aprovação/rejeição de devoluções
        ├── coupons/              # CRUD de cupons da loja
        ├── reviews/              # Moderação de avaliações
        ├── store_settings/       # Configurações da loja
        └── reports/              # Relatórios de vendas e estoque
```

---

## 7. 📁 Árvore de Diretórios: Backend FastAPI

```text
backend/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── alembic/                      # Migrations PostgreSQL
│   ├── alembic.ini
│   ├── env.py
│   └── versions/
│
└── app/
    ├── __init__.py
    ├── main.py                   # App mount, CORS, limiter, exception handler
    ├── database.py               # AsyncSession factory + RLS setter
    ├── config.py                 # Pydantic BaseSettings
    │
    ├── core/
    │   ├── security.py           # JWT encode/decode, password hash, RBAC deps
    │   ├── redis.py              # Redis client singleton
    │   ├── exceptions.py         # Custom HTTP exceptions
    │   └── middleware/
    │       ├── exception_handler.py
    │       ├── idempotency.py    # X-Idempotency-Key middleware
    │       └── rate_limiter.py   # slowapi + Redis
    │
    ├── api/
    │   ├── dependencies/
    │   │   ├── auth.py           # get_current_user, require_role
    │   │   └── tenant.py         # RLS session setter
    │   └── v1/
    │       ├── auth.py
    │       ├── users.py
    │       ├── stores.py
    │       ├── products.py       # CRUD + busca full-text
    │       ├── cart.py           # Operações de carrinho + price check
    │       ├── orders.py
    │       ├── payments.py       # Webhooks idempotentes
    │       ├── coupons.py
    │       ├── reviews.py
    │       ├── wishlists.py
    │       ├── rma.py            # Devoluções
    │       ├── tracking_ws.py    # WebSocket ASGI
    │       └── notifications.py
    │
    ├── models/                   # SQLAlchemy ORM
    │   ├── __init__.py
    │   ├── user.py
    │   ├── address.py
    │   ├── store.py
    │   ├── product.py
    │   ├── sku_variant.py
    │   ├── stock_reservation.py
    │   ├── cart.py
    │   ├── order.py
    │   ├── payment.py
    │   ├── coupon.py
    │   ├── delivery_tracking.py
    │   ├── rma.py
    │   ├── wishlist.py
    │   ├── review.py
    │   └── notification_token.py
    │
    ├── schemas/                  # Pydantic In/Out validation
    │   ├── auth.py
    │   ├── product.py
    │   ├── order.py
    │   ├── cart.py
    │   ├── payment.py
    │   └── rma.py
    │
    └── services/                 # Business logic
        ├── auth_service.py       # Login, registro, refresh, social auth
        ├── geo_service.py        # PostGIS queries + geohash cache
        ├── stock_service.py      # Reserve/confirm/release com Redis lock
        ├── payment_service.py    # Gateway + circuit breaker + estorno
        ├── promotion_service.py  # Cálculo de cupons e regras
        ├── rma_service.py        # Logística reversa + estorno parcial
        ├── notification_service.py # FCM push + in-app
        └── search_service.py     # Full-text via pg_trgm
```

---

## 8. 🧠 Prevenção Lógica Extrema (Corner Cases Resolvidos)

### 8.1 Idempotência Financeira
Se a internet cair imediatamente após o Pix/Cartão e o cliente ficar clicando em "Tentar Novamente", o Flutter gera um `X-Idempotency-Key` (UUID) cravado naquele checkout. O backend reconhece e simplesmente devolve sucesso sem descontar duas vezes, protegendo contra chargebacks.

### 8.2 Isolamento de Carrinho (Single-Store no MVP)
Na etapa inicial do Projeto Zoe, a entidade de Sessão de Carrinho será travada por 1 (um) único `store_id`. Caso o usuário adicione item de outra loja, haverá um *prompt*: "Mudar de Loja? Seu carrinho da Loja XYZ será esvaziado".

### 8.3 Compensação Transacional (Checkout Seguro)
O fluxo de checkout segue o padrão *Saga* simplificado:
1. Reservar estoque (Redis lock + TTL 15min)
2. Processar pagamento (idempotente)
3. Se pagamento falhou → liberar reservas automaticamente
4. Se pagamento ok → confirmar reservas e decrementar estoque real

### 8.4 Carrinho Resistente a OOM
O `CartCubit` usa `HydratedMixin` para serializar o estado em disco a cada emissão. Se o S.O. matar o app, ao reabrir o carrinho é reconstruído integralmente. Ações offline ficam em sync-queue no Drift.

---

## 9. 🐳 Infraestrutura Local (Docker Compose)

```yaml
# docker-compose.yml (referência)
services:
  postgres:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: zoe
      POSTGRES_USER: zoe_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql+asyncpg://zoe_user:${DB_PASSWORD}@postgres:5432/zoe
      REDIS_URL: redis://redis:6379/0
      JWT_SECRET: ${JWT_SECRET}

volumes:
  pgdata:
```

---

## 10. 📚 Dependências Principais

### Backend (Python)
| Pacote | Uso |
|--------|-----|
| `fastapi` | Framework web assíncrono |
| `uvicorn` | ASGI server |
| `sqlalchemy[asyncio]` | ORM assíncrono |
| `asyncpg` | Driver PostgreSQL async |
| `alembic` | Migrations |
| `geoalchemy2` | PostGIS types para SQLAlchemy |
| `redis[hiredis]` | Cache, locks, rate limiting |
| `slowapi` | Rate limiting |
| `python-jose` | JWT encode/decode |
| `passlib[bcrypt]` | Password hashing |
| `pydantic-settings` | Configurações |
| `firebase-admin` | Push notifications |
| `httpx` | Client HTTP para gateways |
| `tenacity` | Retry com backoff |
| `circuitbreaker` | Circuit breaker pattern |

### Flutter (Dart)
| Pacote | Uso |
|--------|-----|
| `flutter_bloc` / `bloc` | Gerenciamento de estado |
| `hydrated_bloc` | Persistência de estado |
| `freezed` / `json_serializable` | Entidades imutáveis |
| `dio` | Cliente HTTP |
| `get_it` / `injectable` | Injeção de dependência |
| `go_router` | Navegação declarativa |
| `drift` | SQLite local (offline) |
| `cached_network_image` | Cache de imagens CDN |
| `geolocator` | GPS |
| `google_maps_flutter` | Mapa de tracking |
| `web_socket_channel` | WebSocket client |
| `firebase_messaging` | Push notifications |
| `uuid` | Geração de chaves de idempotência |
| `shimmer` | Skeleton screens |
| `flutter_animate` | Micro-interações luxury |
