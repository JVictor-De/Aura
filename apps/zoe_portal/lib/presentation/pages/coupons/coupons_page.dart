import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:zoe_portal/domain/entities/portal_coupon.dart';
import 'package:zoe_portal/presentation/cubits/portal_coupons_cubit.dart';

/// Página CRUD de cupons de desconto.
///
/// Exibe tabela de cupons com toggle de ativação, criação e exclusão.
/// Utiliza [PortalCouponsCubit] para gerenciar o estado da lista.
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalCouponsCubit>().loadCoupons();
    });
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
          Row(
            children: [
              Text('Cupons', style: theme.textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCouponDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('NOVO CUPOM'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Content ──
          Expanded(
            child: BlocBuilder<PortalCouponsCubit, PortalCouponsState>(
              builder: (context, state) {
                if (state is PortalCouponsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PortalCouponsError) {
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

                if (state is PortalCouponsLoaded) {
                  if (state.coupons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum cupom cadastrado',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            colorScheme.surfaceContainerHighest,
                          ),
                          columns: const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Valor'), numeric: true),
                            DataColumn(label: Text('Pedido Mín.'), numeric: true),
                            DataColumn(label: Text('Usos')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Expira')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: state.coupons.map((coupon) {
                            final typeLabel =
                                coupon.type == 'percentage' ? '%' : 'R\$';
                            final valueLabel = coupon.type == 'percentage'
                                ? '${coupon.value.toStringAsFixed(0)}%'
                                : 'R\$ ${coupon.value.toStringAsFixed(2)}';

                            return DataRow(cells: [
                              DataCell(
                                Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(Text(typeLabel)),
                              DataCell(Text(valueLabel)),
                              DataCell(Text(
                                coupon.minOrderValue != null
                                    ? 'R\$ ${coupon.minOrderValue!.toStringAsFixed(2)}'
                                    : '—',
                              )),
                              DataCell(Text(
                                '${coupon.usedCount}${coupon.maxUses != null ? ' / ${coupon.maxUses}' : ''}',
                              )),
                              DataCell(
                                Switch(
                                  value: coupon.isActive,
                                  onChanged: (active) {
                                    context
                                        .read<PortalCouponsCubit>()
                                        .toggleCoupon(coupon.id, active);
                                  },
                                ),
                              ),
                              DataCell(Text(
                                coupon.expiresAt != null
                                    ? dateFmt.format(coupon.expiresAt!)
                                    : 'Sem expiração',
                              )),
                              DataCell(
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 20, color: colorScheme.error),
                                  tooltip: 'Excluir',
                                  onPressed: () =>
                                      _showDeleteConfirmation(context, coupon),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
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

  // ── Dialogs ──────────────────────────────────────────────────────────

  void _showCouponDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'percentage';
    DateTime? expiresAt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Cupom'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(),
                        hintText: 'Ex.: MODA10',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de desconto',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Percentual (%)'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Valor fixo (R\$)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueCtrl,
                      decoration: InputDecoration(
                        labelText:
                            selectedType == 'percentage' ? 'Valor (%)' : 'Valor (R\$)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: minOrderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pedido mínimo (R\$) — opcional',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxUsesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Máximo de usos — opcional',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        expiresAt != null
                            ? 'Expira em: ${DateFormat('dd/MM/yyyy').format(expiresAt!)}'
                            : 'Data de expiração — opcional',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => expiresAt = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final data = <String, dynamic>{
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'type': selectedType,
                  'value':
                      double.parse(valueCtrl.text.trim().replaceAll(',', '.')),
                  if (minOrderCtrl.text.trim().isNotEmpty)
                    'min_order_value': double.parse(
                        minOrderCtrl.text.trim().replaceAll(',', '.')),
                  if (maxUsesCtrl.text.trim().isNotEmpty)
                    'max_uses': int.parse(maxUsesCtrl.text.trim()),
                  if (expiresAt != null)
                    'expires_at': expiresAt!.toIso8601String(),
                };
                context.read<PortalCouponsCubit>().createCoupon(data);
                Navigator.of(ctx).pop();
              },
              child: const Text('CRIAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PortalCoupon coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cupom'),
        content: Text(
          'Tem certeza que deseja excluir o cupom "${coupon.code}"?\n'
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<PortalCouponsCubit>().deleteCoupon(coupon.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}
