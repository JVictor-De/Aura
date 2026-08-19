/// Estrutura da tela de catálogo (Product Grid).
///
/// Referências:
/// - ARCHITECTURE.md §presentation/pages/product/product_list_page.dart
/// - TECHNICAL_AUDIT.md §2.1: Hero transition com Curves.easeInOutCubic
/// - TECHNICAL_AUDIT.md §2.3: Skeleton screens elegantes durante loading
import 'package:flutter/material.dart';
import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('CATÁLOGO', style: ZoeTypography.labelLarge),
        backgroundColor: ZoeColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: ZoeSpacing.md,
            mainAxisSpacing: ZoeSpacing.md,
          ),
          itemCount: 6, // Placeholder
          itemBuilder: (context, index) {
            return _ProductCard(
              productId: 'product-$index',
              imageUrl: '',
              brand: 'BRAND',
              name: 'Product Name $index',
              price: 299.90,
              onTap: () {
                // Navigate com Hero transition (TECHNICAL_AUDIT §2.1)
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final String imageUrl;
  final String brand;
  final String name;
  final double price;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.productId,
    required this.imageUrl,
    required this.brand,
    required this.name,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ZoeColors.surface,
          borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: ZoeColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Hero (TECHNICAL_AUDIT §2.1)
            Expanded(
              flex: 4,
              child: Hero(
                tag: 'product-$productId',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ZoeSpacing.radiusMd),
                  ),
                  child: Container(
                    color: ZoeColors.cream,
                    child: const Center(
                      child: Icon(Icons.image, color: ZoeColors.mediumGray, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(ZoeSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      style: ZoeTypography.labelSmall.copyWith(color: ZoeColors.mediumGray),
                    ),
                    const SizedBox(height: ZoeSpacing.xxs),
                    Text(
                      name,
                      style: ZoeTypography.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'R\$ ${price.toStringAsFixed(2)}',
                      style: ZoeTypography.priceMedium,
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
