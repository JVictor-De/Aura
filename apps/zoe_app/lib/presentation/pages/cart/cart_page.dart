import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/cart_item.dart';
import '../../cubits/cart/cart_cubit.dart';
import '../../cubits/cart/cart_state.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('SACOLA', style: ZoeTypography.labelLarge.copyWith(letterSpacing: 3)),
        backgroundColor: ZoeColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoaded && state.items.isNotEmpty) {
            return _CartContent(state: state);
          }
          return _EmptyCart();
        },
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZoeSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ZoeColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 48, color: ZoeColors.primaryLight),
            ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Sua sacola está vazia',
              style: ZoeTypography.headlineMedium.copyWith(color: ZoeColors.charcoal),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 8),
            Text(
              'Explore nossas coleções exclusivas\ne encontre peças que combinam com você',
              style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
              textAlign: TextAlign.center,
            ).animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZoeColors.secondary,
                  foregroundColor: ZoeColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZoeSpacing.radiusLg),
                  ),
                ),
                child: Text(
                  'EXPLORAR',
                  style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.white, letterSpacing: 2),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  final CartLoaded state;
  const _CartContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Store badge
        if (state.currentStoreName != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ZoeSpacing.pagePadding, vertical: ZoeSpacing.sm),
            color: ZoeColors.primaryLight.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.store, size: 16, color: ZoeColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  state.currentStoreName!,
                  style: ZoeTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: ZoeColors.primaryDark),
                ),
              ],
            ),
          ),

        // Items
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _CartItemCard(item: state.items[i])
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),
          ),
        ),

        // Summary + Checkout
        Container(
          padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
          decoration: BoxDecoration(
            color: ZoeColors.surface,
            boxShadow: [
              BoxShadow(
                color: ZoeColors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal (${state.totalItems} ${state.totalItems == 1 ? 'item' : 'itens'})',
                      style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.darkGray)),
                    Text('R\$ ${state.subtotal.toStringAsFixed(2)}', style: ZoeTypography.priceMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Entrega', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray)),
                    Text('Calcular no checkout', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZoeColors.secondary,
                      foregroundColor: ZoeColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ZoeSpacing.radiusLg),
                      ),
                    ),
                    child: Text(
                      'IR PARA O CHECKOUT',
                      style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.white, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ZoeSpacing.sm),
      decoration: BoxDecoration(
        color: ZoeColors.surface,
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
        border: Border.all(color: ZoeColors.lightGray.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: ZoeColors.cream,
              borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
            ),
            child: const Icon(Icons.checkroom, color: ZoeColors.primaryLight, size: 32),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${item.size} · ${item.color}',
                  style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                      style: ZoeTypography.priceMedium.copyWith(fontSize: 16),
                    ),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ZoeColors.lightGray),
                        borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyButton(
                            icon: item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                            onTap: () {
                              if (item.quantity > 1) {
                                context.read<CartCubit>().updateQuantity(item.variantId, item.quantity - 1);
                              } else {
                                context.read<CartCubit>().removeItem(item.variantId);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('${item.quantity}', style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          _QtyButton(
                            icon: Icons.add,
                            onTap: () => context.read<CartCubit>().updateQuantity(item.variantId, item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: ZoeColors.charcoal),
      ),
    );
  }
}
