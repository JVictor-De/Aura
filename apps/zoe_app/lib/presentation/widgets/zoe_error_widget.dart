/// Widget de erro padronizado com retry.
///
/// Referências:
/// - ARCHITECTURE.md §Error Handling
import 'package:flutter/material.dart';

import '../../core/theme/zoe_colors.dart';
import '../../core/theme/zoe_spacing.dart';

class ZoeErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ZoeErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZoeSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: ZoeColors.textSecondary),
            const SizedBox(height: ZoeSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ZoeColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: ZoeSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
