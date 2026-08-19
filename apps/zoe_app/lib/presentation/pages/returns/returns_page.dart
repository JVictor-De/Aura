import 'package:flutter/material.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';

/// ReturnsPage — solicitação de devoluções (RMA).
///
/// Referência: ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('DEVOLUÇÕES', style: ZoeTypography.headlineSmall.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.all(ZoeSpacing.md),
        child: Column(
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ZoeSpacing.md),
              decoration: BoxDecoration(
                color: ZoeColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ZoeColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outlined, color: ZoeColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você pode solicitar devolução em até 7 dias após o recebimento.',
                      style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ZoeSpacing.lg),

            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 64, color: ZoeColors.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Nenhuma devolução', style: ZoeTypography.bodyLarge.copyWith(color: ZoeColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      'Para solicitar uma devolução, acesse\no pedido desejado e toque em "Devolver".',
                      style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
