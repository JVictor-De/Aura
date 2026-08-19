import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/store.dart';

class StoreDetailPage extends StatelessWidget {
  final String storeId;
  const StoreDetailPage({super.key, required this.storeId});

  Store get _store => Store(
    id: storeId,
    name: ['Maison Élégance', 'NOIR Studio', 'Rosa & Ouro', 'Atelier Luxe'][int.tryParse(storeId) != null ? (int.parse(storeId) - 1) % 4 : 0],
    slug: 'store-$storeId',
    description: 'Curadoria exclusiva de peças de alta costura com as principais marcas internacionais. Entrega premium com embalagem especial.',
    latitude: -23.56,
    longitude: -46.65,
    rating: 4.8,
    isActive: true,
    estimatedDeliveryTime: '40-60 min',
  );

  List<Product> get _products => List.generate(6, (i) => Product(
    id: 'sp-$storeId-$i',
    storeId: storeId,
    name: ['Vestido Longo', 'Blazer Slim', 'Sandália Cristal', 'Clutch Acetato', 'Top Cropped', 'Saia Midi'][i],
    description: 'Peça exclusiva',
    brand: ['VALENTINO', 'BALMAIN', 'MANOLO', 'BOTTEGA', 'VERSACE', 'MIU MIU'][i],
    category: ['Vestidos', 'Blazers', 'Sapatos', 'Bolsas', 'Tops', 'Saias'][i],
    imageUrls: [],
    basePrice: [2890, 3450, 4200, 5600, 1200, 1890][i].toDouble(),
    variants: [],
    isActive: true,
  ));

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final products = _products;

    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Store Header ──────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: ZoeColors.secondary,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ZoeColors.secondary, ZoeColors.charcoal],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ZoeColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          store.name[0],
                          style: ZoeTypography.displayMedium.copyWith(color: ZoeColors.white, fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(store.name, style: ZoeTypography.headlineLarge.copyWith(color: ZoeColors.white)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: ZoeColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text('${store.rating}', style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.white)),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, color: ZoeColors.mediumGray, size: 14),
                        const SizedBox(width: 4),
                        Text(store.estimatedDeliveryTime ?? '', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray)),
                        const SizedBox(width: 16),
                        Icon(Icons.local_shipping_outlined, color: ZoeColors.mediumGray, size: 14),
                        const SizedBox(width: 4),
                        Text('Grátis', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Description ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.description ?? '',
                    style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.darkGray, height: 1.6),
                  ),
                  const SizedBox(height: ZoeSpacing.lg),
                  // Info chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(icon: Icons.verified, label: 'Verificada'),
                      _InfoChip(icon: Icons.replay, label: 'Troca fácil'),
                      _InfoChip(icon: Icons.local_offer, label: 'Outlet'),
                      _InfoChip(icon: Icons.card_giftcard, label: 'Gift wrap'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ─── Products Header ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ZoeSpacing.pagePadding, ZoeSpacing.sm, ZoeSpacing.pagePadding, ZoeSpacing.sm),
              child: Text('COLEÇÃO', style: ZoeTypography.labelLarge.copyWith(letterSpacing: 3)),
            ),
          ),

          // ─── Products Grid ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ZoeSpacing.pagePadding),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final product = products[i];
                  return GestureDetector(
                    onTap: () => context.push('/product/${product.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ZoeColors.surface,
                        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: ZoeColors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Hero(
                              tag: 'product-${product.id}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ZoeColors.cream,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(ZoeSpacing.radiusMd)),
                                ),
                                child: Center(child: Icon(_catIcon(product.category), color: ZoeColors.primaryLight, size: 42)),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(ZoeSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.brand, style: ZoeTypography.labelSmall.copyWith(color: ZoeColors.primary, fontSize: 10)),
                                  const SizedBox(height: 3),
                                  Text(product.name, style: ZoeTypography.bodyMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  Text('R\$ ${product.basePrice.toStringAsFixed(2)}', style: ZoeTypography.priceMedium.copyWith(fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                },
                childCount: products.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'vestidos': case 'blazers': case 'tops': case 'saias': return Icons.checkroom;
      case 'bolsas': return Icons.shopping_bag;
      case 'sapatos': return Icons.straighten;
      default: return Icons.style;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ZoeColors.surface,
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusFull),
        border: Border.all(color: ZoeColors.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ZoeColors.primary),
          const SizedBox(width: 6),
          Text(label, style: ZoeTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
