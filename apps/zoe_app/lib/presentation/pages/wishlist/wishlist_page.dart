import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/wishlist_item.dart';
import '../../cubits/wishlist/wishlist_cubit.dart';

/// WishlistPage — favoritos do usuário.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist (Favoritos) e Social Proof
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('FAVORITOS', style: ZoeTypography.headlineSmall.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: ZoeColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Nenhum favorito ainda', style: ZoeTypography.bodyLarge.copyWith(color: ZoeColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Toque no ♡ em qualquer produto para salvar', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(ZoeSpacing.md),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _WishlistTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;

  const _WishlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<WishlistCubit>().removeItem(item.productId);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/product/${item.productId}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: ZoeColors.surface,
                    child: item.imageUrl != null
                        ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: ZoeColors.textSecondary))
                        : const Icon(Icons.image, color: ZoeColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: ZoeTypography.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(item.brand, style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        'R\$ ${item.price.toStringAsFixed(2)}',
                        style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.primary),
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    context.read<WishlistCubit>().removeItem(item.productId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
