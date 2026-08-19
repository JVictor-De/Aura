import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../core/auth/auth_guard.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/wishlist_item.dart';
import '../../cubits/cart/cart_cubit.dart';
import '../../cubits/wishlist/wishlist_cubit.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  // Mock
  final _sizes = ['PP', 'P', 'M', 'G', 'GG'];
  final _colors = [
    {'name': 'Preto', 'hex': 0xFF1A1A1A},
    {'name': 'Champagne', 'hex': 0xFFC9A87C},
    {'name': 'Rose', 'hex': 0xFFB76E79},
    {'name': 'Off-White', 'hex': 0xFFFAF9F7},
  ];

  Product get _product => Product(
    id: widget.productId,
    storeId: '1',
    name: 'Vestido Midi Seda',
    description: 'Elegância atemporal em pura seda italiana. Caimento fluido com corte midi que valoriza a silhueta. Acabamento premium com costuras francesas. Peça versátil para ocasiões especiais e eventos sofisticados.',
    brand: 'VALENTINO',
    category: 'Vestidos',
    imageUrls: [],
    basePrice: 1290.0,
    discountPrice: 1032.0,
    variants: [],
    isActive: true,
  );

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final hasDiscount = product.discountPrice != null;

    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Image Header ──────────────────────────
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: ZoeColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: ZoeColors.surface.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: ZoeColors.charcoal, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: BlocBuilder<WishlistCubit, WishlistState>(
                  builder: (context, wishlistState) {
                    final isFav = context.read<WishlistCubit>().isFavorite(product.id);
                    return CircleAvatar(
                      backgroundColor: ZoeColors.surface.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? ZoeColors.accent : ZoeColors.charcoal,
                          size: 20,
                        ),
                        onPressed: () {
                          if (!AuthGuard.requireAuth(context, returnTo: '/product/${product.id}')) return;
                          context.read<WishlistCubit>().toggleItem(WishlistItem(
                            id: 'w-${product.id}',
                            productId: product.id,
                            productName: product.name,
                            brand: product.brand,
                            price: product.basePrice,
                            discountPrice: product.discountPrice,
                            category: product.category,
                            createdAt: DateTime.now(),
                          ));
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: CircleAvatar(
                  backgroundColor: ZoeColors.surface.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: ZoeColors.charcoal, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  color: ZoeColors.cream,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom, size: 100, color: ZoeColors.primaryLight.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          product.brand,
                          style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.primary, letterSpacing: 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Content ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand + Name
                  Text(product.brand, style: ZoeTypography.labelMedium.copyWith(color: ZoeColors.primary, letterSpacing: 3))
                      .animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 6),
                  Text(product.name, style: ZoeTypography.headlineLarge)
                      .animate(delay: 100.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          'R\$ ${product.discountPrice!.toStringAsFixed(2)}',
                          style: ZoeTypography.priceLarge.copyWith(color: ZoeColors.accent),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'R\$ ${product.basePrice.toStringAsFixed(2)}',
                          style: ZoeTypography.priceStrikethrough.copyWith(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: ZoeColors.accentLight, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '-${((1 - product.discountPrice! / product.basePrice) * 100).round()}%',
                            style: ZoeTypography.labelSmall.copyWith(color: ZoeColors.accent, fontSize: 12),
                          ),
                        ),
                      ] else
                        Text('R\$ ${product.basePrice.toStringAsFixed(2)}', style: ZoeTypography.priceLarge),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 6),
                  Text('ou 10x de R\$ ${((product.discountPrice ?? product.basePrice) / 10).toStringAsFixed(2)} sem juros',
                    style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.success)),

                  const SizedBox(height: ZoeSpacing.sectionGap),

                  // ─── Size Selector ──────────────────
                  Text('TAMANHO', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _sizes.map((s) {
                      final isSelected = _selectedSize == s;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? ZoeColors.secondary : ZoeColors.surface,
                            borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
                            border: Border.all(
                              color: isSelected ? ZoeColors.secondary : ZoeColors.lightGray,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s,
                            style: ZoeTypography.bodyMedium.copyWith(
                              color: isSelected ? ZoeColors.white : ZoeColors.charcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: ZoeSpacing.lg),

                  // ─── Color Selector ─────────────────
                  Text('COR', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _colors.map((c) {
                      final isSelected = _selectedColor == c['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c['name'] as String),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(c['hex'] as int),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? ZoeColors.primary : ZoeColors.lightGray,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, color: (c['hex'] as int) == 0xFFFAF9F7 ? ZoeColors.charcoal : ZoeColors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(c['name'] as String, style: ZoeTypography.bodySmall.copyWith(fontSize: 10)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: ZoeSpacing.sectionGap),

                  // ─── Description ─────────────────────
                  Text('DESCRIÇÃO', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text(product.description, style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.darkGray, height: 1.7)),

                  const SizedBox(height: ZoeSpacing.lg),

                  // ─── Details ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(ZoeSpacing.md),
                    decoration: BoxDecoration(
                      color: ZoeColors.surface,
                      borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
                      border: Border.all(color: ZoeColors.lightGray.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Material', value: '100% Seda Italiana'),
                        const Divider(height: 20, color: ZoeColors.lightGray),
                        _DetailRow(label: 'Cuidados', value: 'Lavagem a seco'),
                        const Divider(height: 20, color: ZoeColors.lightGray),
                        _DetailRow(label: 'Origem', value: 'Itália'),
                        const Divider(height: 20, color: ZoeColors.lightGray),
                        _DetailRow(label: 'Entrega', value: '3-5 dias úteis'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Bar: Add to Cart ─────────────────
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              // Quantity
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: ZoeColors.lightGray),
                  borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_quantity', style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Add to cart
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final item = CartItem(
                        variantId: '${product.id}-${_selectedSize ?? 'M'}-${_selectedColor ?? 'Preto'}',
                        productId: product.id,
                        productName: product.name,
                        size: _selectedSize ?? 'M',
                        color: _selectedColor ?? 'Preto',
                        quantity: _quantity,
                        unitPrice: product.discountPrice ?? product.basePrice,
                        storeId: product.storeId,
                      );
                      context.read<CartCubit>().addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: ZoeColors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('${product.name} adicionado à sacola'),
                            ],
                          ),
                          backgroundColor: ZoeColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: Text(
                      'ADICIONAR — R\$ ${((product.discountPrice ?? product.basePrice) * _quantity).toStringAsFixed(2)}',
                      style: ZoeTypography.labelMedium.copyWith(color: ZoeColors.white, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZoeColors.secondary,
                      foregroundColor: ZoeColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray)),
        Text(value, style: ZoeTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
