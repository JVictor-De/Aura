Contexto
Você é o Desenvolvedor Líder encarregado de iniciar a fase 1 (Foundation + Core) do Zoe, um ecossistema de delivery de moda de luxo com alta criticidade transacional. Toda decisão deve seguir as diretrizes de ARCHITECTURE.md e TECHNICAL_AUDIT.md.

Objetivo
Estruturar backend FastAPI, app Flutter cliente e dashboard web do lojista/admin com segurança, idempotência, isolamento multi-tenant e proteção contra race conditions desde o primeiro commit.

Princípios não negociáveis
- Multi-tenant por loja com isolamento em duas camadas: aplicação + banco (RLS no PostgreSQL).
- Checkout resiliente com idempotência ponta a ponta (header X-Idempotency-Key no cliente e deduplicação no backend).
- Estoque sem overselling: lock distribuído + reserva com TTL + compensação automática em falha de pagamento.
- Sem lógica sensível no frontend (preço final, cupom, total e elegibilidade sempre calculados no backend).
- MVP com carrinho single-store (bloqueio de mistura de lojas no mesmo checkout).

Escopo de Entrega (Fase 1)

1) Backend (FastAPI)
- Estruturar diretórios: app/api, app/core, app/models, app/schemas, app/services, app/api/dependencies, app/core/middleware.
- Implementar base assíncrona com SQLAlchemy AsyncSession + PostgreSQL/PostGIS + Redis.
- Criar models mínimas para fase 1:
  - users, stores, products, sku_variants
  - cart_sessions, cart_items
  - stock_reservations
  - orders, order_shipments, order_items
  - payments, payment_events
- Implementar autenticação diferenciada:
  - customer (app)
  - merchant/admin (portal)
  - RBAC por role e filtro por store_id para merchant.
- Implementar middleware/dependency de idempotência para POST/PATCH críticos (cart, orders, payments).
- Implementar serviço de estoque com:
  - lock distribuído por SKU
  - reserva com TTL de 15 min
  - confirmação/liberação de reserva
  - compensação automática em falha de pagamento.
- Implementar base de observabilidade:
  - request_id, idempotency_key, user_id/store_id no log estruturado.

2) Mobile (Flutter Cliente)
- Estruturar projeto: lib/core, lib/domain, lib/data, lib/presentation/features.
- Configurar Dio com interceptors:
  - auth_interceptor (refresh de JWT)
  - idempotency_interceptor (injeção automática em checkout/pagamento)
  - logging_interceptor (sem vazar dados sensíveis).
- Implementar CartCubit (estado imutável) cobrindo:
  - add/update/remove item
  - single-store lock
  - expiração de reserva
  - alteração de preço no servidor
  - recuperação após OOM com HydratedMixin.
- Implementar Drift para fila offline de operações do carrinho (sync ao reconectar).
- Criar base da tela de catálogo com busca e filtros iniciais (size/color/price range).
- Aplicar ThemeData do design system luxury e Curves.easeInOutCubic nas transições principais.

3) Dashboard Web (Flutter Web)
- Iniciar app do portal para merchant/admin com guardas de rota RBAC.
- Implementar fluxo crítico de inventário:
  - CRUD de SKU por variação (tamanho, cor, preço, estoque)
  - atualização de estoque com validação server-side.
- Implementar painel de pedidos em tempo real:
  - WebSocket para status de pedidos
  - fallback polling 30s
  - exibir apenas shipments/orders da loja autenticada (merchant).

4) Integração e Operação
- Entregar árvore de diretórios completa dos 3 projetos.
- Documentar configuração do banco, Redis e migrações iniciais.
- Incluir código base de:
  - CartCubit
  - modelo de autenticação backend (customer x merchant/admin)
  - serviço de reserva/compensação de estoque.
- Incluir guia de execução inicial com Docker Compose.

Critérios de Aceite Técnicos
- Nenhum endpoint crítico aceita requisição sem idempotency key quando aplicável.
- Não existe leitura de pedidos de outra loja por merchant (validação em testes de autorização).
- Em falha no pagamento, reserva de estoque é sempre liberada (compensação garantida).
- Em reconexão de rede, fila offline do carrinho sincroniza sem duplicar itens.
- CartCubit restaura estado após kill do app por OOM.

Restrições
- Não usar soluções genéricas ou somente teóricas.
- Não remover controles definidos em ARCHITECTURE.md e TECHNICAL_AUDIT.md.
- Não mover cálculo de total/cupom para o frontend.

Formato de saída esperado (ao executar este prompt)
- Código + estrutura de pastas + exemplos mínimos executáveis.
- Explicação objetiva de cada decisão com referência explícita às seções relevantes de:
  - ARCHITECTURE.md
  - TECHNICAL_AUDIT.md
