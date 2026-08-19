import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/store.dart';
import '../../cubits/catalog/catalog_cubit.dart';
import '../../cubits/address/address_cubit.dart';
import '../../cubits/notification/notification_cubit.dart';

// ─── Categories (UI navigation, not data) ───────────────────
const _categories = [
  {'icon': Icons.checkroom, 'label': 'Roupas'},
  {'icon': Icons.diamond, 'label': 'Joias'},
  {'icon': Icons.shopping_bag, 'label': 'Bolsas'},
  {'icon': Icons.watch, 'label': 'Relógios'},
  {'icon': Icons.straighten, 'label': 'Sapatos'},
  {'icon': Icons.auto_awesome, 'label': 'Perfumes'},
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressCubit = context.read<AddressCubit>();
      context.read<CatalogCubit>().loadHome(
            lat: addressCubit.currentLat,
            lng: addressCubit.currentLng,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: ZoeColors.surface,
            elevation: 0,
            toolbarHeight: 70,
            title: BlocBuilder<AddressCubit, AddressState>(
              builder: (context, addressState) {
                final String addressLabel;
                if (addressState is AddressSelected) {
                  addressLabel = addressState.address.label.isNotEmpty
                      ? addressState.address.label
                      : addressState.address.street;
                } else {
                  addressLabel = 'Selecionar endereço';
                }
                return GestureDetector(
                  onTap: () => context.push('/address'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entregar em',
                        style: ZoeTypography.bodySmall
                            .copyWith(color: ZoeColors.mediumGray),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: ZoeColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              addressLabel,
                              style: ZoeTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              color: ZoeColors.darkGray, size: 18),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, notifState) {
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: notifState.hasUnread,
                      label: Text('${notifState.unreadCount}'),
                      backgroundColor: ZoeColors.accent,
                      child: const Icon(Icons.notifications_outlined,
                          color: ZoeColors.charcoal),
                    ),
                    onPressed: () => context.push('/notifications'),
                  );
                },
              ),
            ],
          ),

          // ─── Search Bar ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ZoeSpacing.pagePadding,
                  ZoeSpacing.sm, ZoeSpacing.pagePadding, ZoeSpacing.md),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: ZoeColors.cream,
                    borderRadius: BorderRadius.circular(ZoeSpacing.radiusLg),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: ZoeColors.mediumGray, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Buscar marcas, produtos...',
                        style: ZoeTypography.bodyMedium
                            .copyWith(color: ZoeColors.mediumGray),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ─── Categories ─────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: ZoeSpacing.pagePadding),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  return GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: ZoeColors.surface,
                            borderRadius:
                                BorderRadius.circular(ZoeSpacing.radiusMd),
                            border: Border.all(color: ZoeColors.lightGray),
                          ),
                          child: Icon(cat['icon'] as IconData,
                              color: ZoeColors.primary, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['label'] as String,
                          style: ZoeTypography.labelSmall.copyWith(fontSize: 11),
                        ),
                      ],
                    )
                        .animate(delay: Duration(milliseconds: 80 * i))
                        .fadeIn(duration: 400.ms)
                        .slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutCubic),
                  );
                },
              ),
            ),
          ),

          // ─── Catalog content (stores + products) ────
          BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, catalogState) {
              if (catalogState is CatalogLoading ||
                  catalogState is CatalogInitial) {
                return _buildShimmerSkeleton();
              }

              if (catalogState is CatalogError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: ZoeColors.error, size: 48),
                          const SizedBox(height: ZoeSpacing.sm),
                          Text(catalogState.message,
                              style: ZoeTypography.bodyMedium
                                  .copyWith(color: ZoeColors.error)),
                          const SizedBox(height: ZoeSpacing.md),
                          OutlinedButton(
                            onPressed: () {
                              final addressCubit =
                                  context.read<AddressCubit>();
                              context.read<CatalogCubit>().loadHome(
                                    lat: addressCubit.currentLat,
                                    lng: addressCubit.currentLng,
                                  );
                            },
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final stores = catalogState is CatalogLoaded
                  ? catalogState.stores
                  : <Store>[];
              final products = catalogState is CatalogLoaded
                  ? catalogState.products
                  : <Product>[];

              return _buildCatalogContent(stores, products);
            },
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── Catalog content slivers ────────────────────────────
  Widget _buildCatalogContent(List<Store> stores, List<Product> products) {
    return SliverMainAxisGroup(
      slivers: [
        // Nearby Stores header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ZoeSpacing.pagePadding,
                ZoeSpacing.lg, ZoeSpacing.pagePadding, ZoeSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LOJAS PRÓXIMAS', style: ZoeTypography.labelLarge),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: Text('Ver todas',
                      style: ZoeTypography.bodySmall
                          .copyWith(color: ZoeColors.primary)),
                ),
              ],
            ),
          ),
        ),

        // Nearby Stores list
        SliverToBoxAdapter(
          child: SizedBox(
            height: 170,
            child: stores.isEmpty
                ? Center(
                    child: Text('Nenhuma loja encontrada',
                        style: ZoeTypography.bodyMedium
                            .copyWith(color: ZoeColors.mediumGray)),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: ZoeSpacing.pagePadding),
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => _StoreCard(store: stores[i])
                        .animate(delay: Duration(milliseconds: 100 * i))
                        .fadeIn(duration: 400.ms)
                        .slideX(
                            begin: 0.15,
                            end: 0,
                            curve: Curves.easeOutCubic),
                  ),
          ),
        ),

        // Featured Products header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ZoeSpacing.pagePadding,
                ZoeSpacing.sectionGap, ZoeSpacing.pagePadding, ZoeSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DESTAQUES', style: ZoeTypography.labelLarge),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: Text('Ver todos',
                      style: ZoeTypography.bodySmall
                          .copyWith(color: ZoeColors.primary)),
                ),
              ],
            ),
          ),
        ),

        // Featured Products grid
        if (products.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
              child: Center(
                child: Text('Nenhum produto encontrado',
                    style: ZoeTypography.bodyMedium
                        .copyWith(color: ZoeColors.mediumGray)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: ZoeSpacing.pagePadding),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ProductCard(product: products[i])
                    .animate(delay: Duration(milliseconds: 80 * i))
                    .fadeIn(duration: 400.ms)
                    .slideY(
                        begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                childCount: products.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Shimmer loading skeleton ───────────────────────────
  Widget _buildShimmerSkeleton() {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: ZoeColors.lightGray,
        highlightColor: ZoeColors.cream,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: ZoeSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: ZoeSpacing.lg),
              // Section title placeholder
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: ZoeColors.white,
                  borderRadius: BorderRadius.circular(ZoeSpacing.radiusXs),
                ),
              ),
              const SizedBox(height: ZoeSpacing.md),
              // Stores row placeholder
              SizedBox(
                height: 170,
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 14 : 0),
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: ZoeColors.white,
                          borderRadius:
                              BorderRadius.circular(ZoeSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ZoeSpacing.sectionGap),
              // Section title placeholder
              Container(
                width: 110,
                height: 16,
                decoration: BoxDecoration(
                  color: ZoeColors.white,
                  borderRadius: BorderRadius.circular(ZoeSpacing.radiusXs),
                ),
              ),
              const SizedBox(height: ZoeSpacing.md),
              // Products grid placeholder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: ZoeColors.white,
                    borderRadius:
                        BorderRadius.circular(ZoeSpacing.radiusMd),
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

// ─── Store Card ─────────────────────────────────────────────
class _StoreCard extends StatelessWidget {
  final Store store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/store/${store.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: ZoeColors.surface,
          borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
          border: Border.all(color: ZoeColors.lightGray.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ZoeColors.primaryLight, ZoeColors.cream],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ZoeSpacing.radiusMd)),
              ),
              child: Center(
                child: Text(
                  store.name[0],
                  style: ZoeTypography.displaySmall.copyWith(
                    color: ZoeColors.primary,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(ZoeSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: ZoeTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: ZoeColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text('${store.rating}',
                          style: ZoeTypography.bodySmall),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          color: ZoeColors.mediumGray, size: 13),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(store.estimatedDeliveryTime ?? '',
                            style: ZoeTypography.bodySmall
                                .copyWith(color: ZoeColors.mediumGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ───────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPrice != null;
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
            // Image placeholder
            Expanded(
              flex: 5,
              child: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color: ZoeColors.cream,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(ZoeSpacing.radiusMd)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _categoryIcon(product.category),
                          color: ZoeColors.primaryLight,
                          size: 52,
                        ),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ZoeColors.accent,
                              borderRadius:
                                  BorderRadius.circular(ZoeSpacing.radiusXs),
                            ),
                            child: Text(
                              '-${((1 - product.discountPrice! / product.basePrice) * 100).round()}%',
                              style: const TextStyle(
                                  color: ZoeColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ZoeColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border,
                              size: 16, color: ZoeColors.darkGray),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(ZoeSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.toUpperCase(),
                      style: ZoeTypography.labelSmall
                          .copyWith(color: ZoeColors.primary, fontSize: 10),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      style: ZoeTypography.bodyMedium
                          .copyWith(fontSize: 13, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (hasDiscount) ...[
                      Text(
                        'R\$ ${product.basePrice.toStringAsFixed(2)}',
                        style: ZoeTypography.priceStrikethrough
                            .copyWith(fontSize: 12),
                      ),
                      Text(
                        'R\$ ${product.discountPrice!.toStringAsFixed(2)}',
                        style: ZoeTypography.priceMedium
                            .copyWith(fontSize: 15, color: ZoeColors.accent),
                      ),
                    ] else
                      Text(
                        'R\$ ${product.basePrice.toStringAsFixed(2)}',
                        style: ZoeTypography.priceMedium.copyWith(fontSize: 15),
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vestidos':
      case 'roupas':
        return Icons.checkroom;
      case 'bolsas':
        return Icons.shopping_bag;
      case 'joias':
        return Icons.diamond;
      case 'sapatos':
        return Icons.straighten;
      case 'acessórios':
        return Icons.auto_awesome;
      default:
        return Icons.style;
    }
  }
}
