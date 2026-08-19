import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';

/// OrderSuccessPage — confirmação de pedido realizado.
///
/// Referência: ARCHITECTURE.md §Checkout Saga → tela de sucesso
class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ZoeSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              ),
              const SizedBox(height: 32),

              Text('Pedido Confirmado!', style: ZoeTypography.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Seu pedido #${orderId.substring(0, 8).toUpperCase()} foi realizado com sucesso.',
                style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Track order button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZoeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/tracking/$orderId'),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(
                    'ACOMPANHAR PEDIDO',
                    style: ZoeTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Go home button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZoeColors.primary,
                    side: const BorderSide(color: ZoeColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'VOLTAR AO INÍCIO',
                    style: ZoeTypography.labelLarge.copyWith(letterSpacing: 1.2),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
