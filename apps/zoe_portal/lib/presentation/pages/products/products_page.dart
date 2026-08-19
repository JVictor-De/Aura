import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_product.dart';
import 'package:zoe_portal/presentation/cubits/portal_inventory_cubit.dart';

/// Página CRUD de produtos do merchant.
///
/// Exibe tabela de produtos com ações de criar, editar e excluir.
/// Utiliza [PortalInventoryCubit] para gerenciar o estado da lista.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalInventoryCubit>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Text('Produtos', style: theme.textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showProductDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('NOVO PRODUTO'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Content ──
          Expanded(
            child: BlocBuilder<PortalInventoryCubit, PortalInventoryState>(
              builder: (context, state) {
                if (state is PortalInventoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PortalInventoryError) {
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

                if (state is PortalInventoryLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum produto cadastrado',
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
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Marca')),
                            DataColumn(label: Text('Categoria')),
                            DataColumn(label: Text('Preço'), numeric: true),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: state.products.map((product) {
                            return DataRow(cells: [
                              DataCell(Text(product.name)),
                              DataCell(Text(product.brand)),
                              DataCell(Text(product.category)),
                              DataCell(Text(
                                'R\$ ${product.basePrice.toStringAsFixed(2)}',
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.isActive
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : colorScheme.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    product.isActive ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: product.isActive
                                          ? Colors.green
                                          : colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Editar',
                                    onPressed: () =>
                                        _showProductDialog(context, product: product),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 20, color: colorScheme.error),
                                    tooltip: 'Excluir',
                                    onPressed: () =>
                                        _showDeleteConfirmation(context, product),
                                  ),
                                ],
                              )),
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

  void _showProductDialog(BuildContext context, {PortalProduct? product}) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final priceCtrl = TextEditingController(
      text: product != null ? product.basePrice.toStringAsFixed(2) : '',
    );
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Produto' : 'Novo Produto'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preço base (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
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
              final data = {
                'name': nameCtrl.text.trim(),
                'brand': brandCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'base_price': double.parse(
                    priceCtrl.text.trim().replaceAll(',', '.')),
                'description': descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              };
              final cubit = context.read<PortalInventoryCubit>();
              if (isEditing) {
                cubit.updateProduct(product.id, data);
              } else {
                cubit.createProduct(data);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(isEditing ? 'SALVAR' : 'CRIAR'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PortalProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text(
          'Tem certeza que deseja excluir "${product.name}"?\n'
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
              context.read<PortalInventoryCubit>().deleteProduct(product.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}
