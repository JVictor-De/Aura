/// BottomSheet de conflito de loja no carrinho.
///
/// Referências:
/// - ARCHITECTURE.md §2.7: Single-Store Cart Isolation
/// - TECHNICAL_AUDIT.md §F-2: Store Conflict — Dialog com opções
import 'package:flutter/material.dart';

import '../../core/theme/zoe_colors.dart';
import '../../core/theme/zoe_spacing.dart';

class StoreConflictBottomSheet extends StatelessWidget {
  final String currentStoreName;
  final String newStoreName;
  final VoidCallback onClearAndAdd;
  final VoidCallback onCancel;

  const StoreConflictBottomSheet({
    super.key,
    required this.currentStoreName,
    required this.newStoreName,
    required this.onClearAndAdd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ZoeSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ZoeColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: ZoeSpacing.lg),
            Icon(
              Icons.store_outlined,
              size: 48,
              color: ZoeColors.warning,
            ),
            const SizedBox(height: ZoeSpacing.md),
            Text(
              'Itens de outra loja',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZoeSpacing.sm),
            Text(
              'Seu carrinho contém itens de $currentStoreName. '
              'Deseja limpar o carrinho e adicionar itens de $newStoreName?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ZoeColors.textSecondary,
                  ),
            ),
            const SizedBox(height: ZoeSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClearAndAdd,
                child: Text('Limpar e adicionar de $newStoreName'),
              ),
            ),
            const SizedBox(height: ZoeSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child: Text('Manter itens de $currentStoreName'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe o bottom sheet de conflito de loja.
  static Future<bool?> show(
    BuildContext context, {
    required String currentStoreName,
    required String newStoreName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StoreConflictBottomSheet(
        currentStoreName: currentStoreName,
        newStoreName: newStoreName,
        onClearAndAdd: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }
}
