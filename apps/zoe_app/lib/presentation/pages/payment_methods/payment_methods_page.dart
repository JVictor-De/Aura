import 'package:flutter/material.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/payment_method.dart';

/// PaymentMethodsPage — gerenciar métodos de pagamento.
///
/// Referência: ARCHITECTURE.md §2.2: Pagamento / Checkout
class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock payment methods — in production, loaded from backend
    final methods = <PaymentMethod>[
      const PaymentMethod(
        id: '1',
        type: 'credit_card',
        lastFourDigits: '4242',
        brand: 'Visa',
        isDefault: true,
      ),
      const PaymentMethod(
        id: '2',
        type: 'credit_card',
        lastFourDigits: '8888',
        brand: 'Mastercard',
      ),
      const PaymentMethod(
        id: '3',
        type: 'pix',
      ),
    ];

    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('PAGAMENTO', style: ZoeTypography.headlineSmall.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZoeColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          // Add new payment method
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar método — em breve')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('ADICIONAR'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(ZoeSpacing.md),
        itemCount: methods.length,
        itemBuilder: (context, index) {
          final method = methods[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: method.isDefault
                  ? const BorderSide(color: ZoeColors.primary, width: 1.5)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ZoeColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      method.type == 'pix' ? Icons.qr_code : Icons.credit_card,
                      color: ZoeColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_methodLabel(method), style: ZoeTypography.bodyLarge),
                        if (method.isDefault) ...[
                          const SizedBox(height: 4),
                          Text('Padrão', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.primary)),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      // Handle action
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'default', child: Text('Definir como padrão')),
                      const PopupMenuItem(value: 'remove', child: Text('Remover')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _methodLabel(PaymentMethod method) {
    if (method.type == 'pix') return 'PIX';
    final brand = method.brand ?? 'Cartão';
    final digits = method.lastFourDigits ?? '****';
    return '$brand •••• $digits';
  }
}
