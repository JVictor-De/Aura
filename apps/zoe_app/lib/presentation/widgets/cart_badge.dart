/// Badge do carrinho com contador animado.
///
/// Referências:
/// - ARCHITECTURE.md §Design System: ícone de carrinho com badge
/// - prompt.md §3.1: flutter_animate
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/zoe_colors.dart';
import '../cubits/cart/cart_cubit.dart';
import '../cubits/cart/cart_state.dart';

class CartBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const CartBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        int count = 0;
        if (state is CartLoaded) {
          count = state.totalItems;
        }

        return IconButton(
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: ZoeColors.primary,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        );
      },
    );
  }
}
