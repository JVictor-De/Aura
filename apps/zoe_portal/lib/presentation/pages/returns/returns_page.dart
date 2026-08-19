import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:zoe_portal/domain/entities/portal_rma.dart';
import 'package:zoe_portal/presentation/cubits/portal_rma_cubit.dart';

/// Página de gerenciamento de devoluções (RMA).
///
/// Exibe lista de solicitações de devolução com filtros por status
/// e ações de aprovação/rejeição para solicitações pendentes.
class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  String _selectedFilter = 'all';

  static const _filters = <String, String>{
    'all': 'Todos',
    'requested': 'Pendentes',
    'approved': 'Aprovados',
    'rejected': 'Rejeitados',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalRmaCubit>().loadRmas();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    final cubit = context.read<PortalRmaCubit>();
    if (filter == 'all') {
      cubit.loadRmas();
    } else {
      cubit.loadRmas(status: filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text('Devoluções', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // ── Filter Chips ──
          Wrap(
            spacing: 8,
            children: _filters.entries.map((entry) {
              final selected = _selectedFilter == entry.key;
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => _onFilterChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Content ──
          Expanded(
            child: BlocBuilder<PortalRmaCubit, PortalRmaState>(
              builder: (context, state) {
                if (state is PortalRmaLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PortalRmaError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(state.message, style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  );
                }

                if (state is PortalRmaLoaded) {
                  final rmas = state.rmas;
                  if (rmas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_return_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma devolução encontrada',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: rmas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rma = rmas[index];
                      return _RmaCard(
                        rma: rma,
                        dateFmt: dateFmt,
                        colorScheme: colorScheme,
                        theme: theme,
                        onApprove: rma.status == 'requested'
                            ? () => context
                                .read<PortalRmaCubit>()
                                .updateRmaStatus(rma.id, 'approved')
                            : null,
                        onReject: rma.status == 'requested'
                            ? () => context
                                .read<PortalRmaCubit>()
                                .updateRmaStatus(rma.id, 'rejected')
                            : null,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RMA Card Widget ─────────────────────────────────────────────────

class _RmaCard extends StatelessWidget {
  final PortalRma rma;
  final DateFormat dateFmt;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RmaCard({
    required this.rma,
    required this.dateFmt,
    required this.colorScheme,
    required this.theme,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Order ID, customer, status badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${rma.orderId}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rma.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: rma.status, colorScheme: colorScheme),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details row
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _DetailChip(
                  icon: Icons.comment_outlined,
                  label: 'Motivo',
                  value: rma.reason,
                ),
                _DetailChip(
                  icon: Icons.attach_money,
                  label: 'Estorno',
                  value: 'R\$ ${rma.refundAmount.toStringAsFixed(2)}',
                ),
                _DetailChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: dateFmt.format(rma.createdAt),
                ),
              ],
            ),

            // Items
            if (rma.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Itens:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              ...rma.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '• ${item.productName} (${item.sku}) × ${item.quantity}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],

            // Action buttons for pending RMAs
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprovar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final ColorScheme colorScheme;

  const _StatusBadge({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = switch (status) {
      'requested' => ('Pendente', Colors.orange.withValues(alpha: 0.12), Colors.orange),
      'approved' => ('Aprovado', Colors.green.withValues(alpha: 0.12), Colors.green),
      'rejected' => ('Rejeitado', colorScheme.error.withValues(alpha: 0.12), colorScheme.error),
      'completed' => ('Concluído', Colors.blue.withValues(alpha: 0.12), Colors.blue),
      _ => ('Desconhecido', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fgColor),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
