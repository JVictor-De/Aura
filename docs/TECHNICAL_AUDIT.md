# 🔍 TECHNICAL_AUDIT.md — Zoe (Atualizado para Produção)

## 1. Escopo da Auditoria
Este documento consolida os riscos técnicos e controles mandatórios para o Zoe, cobrindo:
- Backend FastAPI assíncrono com PostgreSQL/PostGIS/Redis
- App Flutter cliente
- Portal Flutter Web (merchant/admin)
- Fluxos críticos: carrinho, estoque, checkout, pagamento, RBAC e multi-tenant

Base de referência:
- ARCHITECTURE.md (seções 2, 3, 4, 8, 9)

---

## 2. Premissas de Segurança e Consistência

### 2.1 Multi-tenant (obrigatório)
- Isolamento por `store_id` para entidades de lojista.
- Validação em duas camadas:
  1) Filtro de aplicação (dependencies auth/tenant)
  2) RLS no PostgreSQL para impedir vazamento por erro de query.

### 2.2 Idempotência (obrigatório)
- Header `X-Idempotency-Key` exigido em operações críticas:
  - criação de pedido
  - pagamento
  - mutações críticas de carrinho
- Resultado deve ser deduplicado no backend por janela temporal (TTL) com Redis + persistência em tabela de eventos críticos.

### 2.3 Integridade de estoque (obrigatório)
- Lock distribuído por SKU no momento de reserva.
- Reserva com TTL (15 min) em `stock_reservations`.
- Compensação obrigatória:
  - pagamento falhou => liberar reserva
  - pagamento aprovado => confirmar reserva e baixar estoque.

### 2.4 MVP de carrinho
- Carrinho **single-store**.
- Ao tentar adicionar item de outra loja, fluxo deve exigir confirmação e limpar carrinho atual.

---

## 3. Matriz de Riscos (Fase 1)

| ID | Risco | Severidade | Probabilidade | Controle obrigatório | Evidência de aceite |
|---|---|---|---|---|---|
| R1 | Overselling da última unidade | Crítica | Alta | lock distribuído + TTL + confirmação transacional | teste concorrente com 2 compradores, apenas 1 sucesso |
| R2 | Cobrança duplicada | Crítica | Média | idempotência end-to-end | mesma key retorna mesma resposta sem novo débito |
| R3 | Vazamento entre lojistas | Crítica | Média | RBAC + filtro por loja + RLS | merchant A não acessa dados de merchant B |
| R4 | Reserva órfã após falha de pagamento | Alta | Média | compensação automática | reserva removida ao falhar pagamento |
| R5 | Carrinho perdido por OOM | Alta | Alta | HydratedMixin + Drift | estado restaurado após kill do app |
| R6 | Divergência preço frontend/backend | Alta | Média | preço final backend-driven | checkout sempre retorna total revalidado |
| R7 | Queda de WS sem atualização de pedidos | Média | Alta | fallback polling 30s | painel segue atualizando sem WS |
| R8 | Abuso de autenticação (brute force) | Alta | Média | rate limiting por IP/rota + lockout | `/auth/login` limitado e auditado |

---

## 4. Controles Mandatórios por Camada

### 4.1 Backend (FastAPI)

### A. Controle de concorrência e estoque
- Serviço de estoque deve:
  - reservar (`active`)
  - confirmar (`confirmed`)
  - liberar (`released`)
  - expirar (`expired`)
- Toda alteração de estado deve ser auditável (`created_at`, `updated_at`, `reason`).

### B. Middleware de idempotência
- Requisito:
  - validar presença de `X-Idempotency-Key` em rotas críticas
  - bloquear reprocessamento
  - retornar payload original (ou referência da transação original)

### C. Segurança e RBAC
- Perfis: `customer`, `merchant`, `admin`.
- `merchant` sempre escopado a `store_id`.
- `admin` com trilha de auditoria para operações sensíveis.

### D. Rate limiting
- Exemplo mínimo:
  - `/api/v1/auth/login`: 5 req/min por IP
  - rotas públicas: 100 req/min por IP
- Persistência de counters em Redis.

### E. Observabilidade
- Logs estruturados com:
  - `request_id`
  - `idempotency_key`
  - `user_id`
  - `store_id`
  - `endpoint`
  - `latency_ms`

### 4.2 Flutter Cliente

### A. CartCubit resiliente
Estados mínimos esperados:
- `CartIdle`
- `CartLoading`
- `CartLoaded`
- `CartStoreConflict`
- `CartPriceChanged`
- `CartReservationExpiring`
- `CartError`

Comportamentos mandatórios:
- processamento sequencial de mutações
- rollback em falha de sincronização
- persistência local via HydratedMixin
- sync queue no Drift para offline/reconexão

### B. Camada de rede
Interceptors obrigatórios:
- Auth refresh JWT
- Idempotency key para operações críticas
- Logging com mascaramento de dados sensíveis

### C. UX crítica
- feedback de expiração de reserva
- confirmação quando preço mudar
- bloqueio de checkout com estoque inválido

### 4.3 Portal (Flutter Web)

### A. RBAC de rota e dado
- Guardas de rota por role.
- Query de pedidos/estoque sempre filtrada por loja do token do merchant.

### B. Tempo real
- WebSocket para pedidos em tempo real.
- Fallback polling a cada 30s se WS indisponível.

### C. Inventário
- CRUD SKU com validação server-side.
- Atualizações de estoque com controle de versão/concorrência.

---

## 5. Fluxos Críticos Auditados

### 5.1 Checkout seguro (Saga simplificada)
1. Cliente inicia checkout com `X-Idempotency-Key`.
2. Backend reserva estoque (TTL 15 min).
3. Backend processa pagamento (idempotente).
4. Se pagamento falha => libera reservas.
5. Se pagamento aprova => confirma reservas e cria order shipments/items.
6. Publica evento para tracking/notificação.

Critério de aprovação:
- Não pode existir estado final com `payment=failed` e `reservation=active`.

### 5.2 Carrinho com conflito de loja
1. Carrinho ativo possui `store_id=A`.
2. Usuário tenta adicionar item de `store_id=B`.
3. App emite `CartStoreConflict` e exige confirmação.
4. Confirmado => limpa sessão atual e inicia nova sessão de carrinho para B.

Critério de aprovação:
- Nunca persistir itens de lojas diferentes na mesma `cart_session`.

### 5.3 Reexecução segura (idempotência)
1. Cliente dispara pagamento.
2. Timeout de rede no retorno.
3. Cliente reenvia mesma `X-Idempotency-Key`.
4. Backend retorna resultado da transação original sem novo débito.

Critério de aprovação:
- Apenas 1 registro efetivo de transação no gateway por operação lógica.

---

## 6. Contratos Técnicos Recomendados

### 6.1 Header obrigatório
- `Authorization: Bearer <token>`
- `X-Request-Id: <uuid>`
- `X-Idempotency-Key: <uuid>` (rotas críticas)

### 6.2 Erros padronizados
Payload mínimo:
```json
{
  "code": "STOCK_UNAVAILABLE",
  "message": "Estoque insuficiente para a variação selecionada.",
  "details": {
    "sku": "DRESS-BLK-M",
    "available": 0
  },
  "request_id": "..."
}
```

### 6.3 Eventos de domínio (mínimo)
- `stock.reserved`
- `stock.released`
- `payment.approved`
- `payment.failed`
- `order.created`
- `order.shipment.updated`

---

## 7. Plano de Testes de Auditoria (gate de release)

### 7.1 Backend
- Teste concorrente de compra última unidade.
- Teste de reenvio com mesma idempotency key.
- Teste de RBAC cross-tenant (merchant A x merchant B).
- Teste de compensação automática após falha de pagamento.

### 7.2 Flutter App
- Teste de restauração de carrinho após kill por OOM.
- Teste de fila offline com reconexão.
- Teste de conflito de loja no carrinho.
- Teste de mudança de preço antes do checkout.

### 7.3 Portal
- Teste de filtros de pedido por loja autenticada.
- Teste de fallback de WS para polling.

---

## 8. Dívidas Técnicas Aceitáveis no MVP (explícitas)
- Sem Elasticsearch (usar `pg_trgm` + GIN).
- Sem event bus externo dedicado (usar publicação interna com evolução futura).
- Sem multi-store checkout (mantido single-store por decisão de risco operacional).

---

## 9. Checklist de Aprovação de Fase 1
- [ ] Estrutura de diretórios dos 3 projetos implementada
- [ ] RLS habilitado e validado em ambiente local
- [ ] Middleware/dependency de idempotência ativo
- [ ] Serviço de reserva/liberação/expiração de estoque operacional
- [ ] CartCubit com persistência e sync queue funcionando
- [ ] RBAC portal e backend validado
- [ ] Docker Compose sobe PostGIS + Redis + Backend
- [ ] Testes críticos de auditoria executados

---

## 10. Decisão final da auditoria
A arquitetura está apta para iniciar codificação imediata desde que os controles mandatórios deste documento sejam implementados no primeiro ciclo (Fase 1). Qualquer flexibilização em idempotência, RLS ou compensação transacional é bloqueadora de produção.
