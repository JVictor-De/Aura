import 'package:flutter/material.dart';

import 'package:zoe_portal/domain/entities/store_settings.dart';

/// Página de configurações da loja.
///
/// Formulário com campos editáveis para as configurações da loja do merchant.
/// Usa dados mock por enquanto (sem cubit). Exibe SnackBar ao salvar.
class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Mock data
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _deliveryTimeCtrl;
  late final TextEditingController _minOrderCtrl;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // Inicializar com dados mock — simula StoreSettings carregado da API
    const mock = StoreSettings(
      storeId: 'store-001',
      storeName: 'Zoe Fashion',
      description: 'Moda feminina com curadoria exclusiva',
      isActive: true,
      deliveryFee: 12.90,
      estimatedDeliveryTime: '3-5 dias úteis',
      minOrderValue: 79.90,
    );

    _nameCtrl = TextEditingController(text: mock.storeName);
    _descCtrl = TextEditingController(text: mock.description ?? '');
    _deliveryFeeCtrl =
        TextEditingController(text: mock.deliveryFee.toStringAsFixed(2));
    _deliveryTimeCtrl =
        TextEditingController(text: mock.estimatedDeliveryTime);
    _minOrderCtrl = TextEditingController(
      text: mock.minOrderValue?.toStringAsFixed(2) ?? '',
    );
    _isActive = mock.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _minOrderCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    // Em produção: enviar dados via cubit/service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Configurações salvas com sucesso!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
          Text('Configurações da Loja', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),

          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informações Gerais',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),

                          // Store Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nome da Loja',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          Text('Entrega', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),

                          // Delivery Fee
                          TextFormField(
                            controller: _deliveryFeeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Taxa de Entrega (R\$)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obrigatório';
                              }
                              if (double.tryParse(v.replaceAll(',', '.')) ==
                                  null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Estimated Delivery Time
                          TextFormField(
                            controller: _deliveryTimeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tempo Estimado de Entrega',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule_outlined),
                              hintText: 'Ex.: 3-5 dias úteis',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          Text('Pedido', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),

                          // Min Order Value
                          TextFormField(
                            controller: _minOrderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Valor Mínimo do Pedido (R\$) — opcional',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_cart_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                if (double.tryParse(v.replaceAll(',', '.')) ==
                                    null) {
                                  return 'Valor inválido';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Active toggle
                          SwitchListTile(
                            title: const Text('Loja Ativa'),
                            subtitle: Text(
                              _isActive
                                  ? 'Sua loja está visível para os clientes'
                                  : 'Sua loja está oculta para os clientes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 32),

                          // Save button
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _onSave,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('SALVAR CONFIGURAÇÕES'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
