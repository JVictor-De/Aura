import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../../domain/entities/product.dart';

// ─── Mock Data ──────────────────────────────────────────────
final _mockProducts = List.generate(12, (i) => Product(
  id: 'p-$i',
  storeId: '${(i % 4) + 1}',
  name: [
    'Vestido Midi Seda', 'Blazer Oversized', 'Bolsa Pochette', 'Colar Pérolas',
    'Scarpin Cetim', 'Óculos Cat-Eye', 'Lenço Cashmere', 'Calça Alfaiataria',
    'Jaqueta Couro', 'Saia Plissada', 'Anel Diamante', 'Brincos Ouro',
  ][i],
  description: 'Peça exclusiva',
  brand: [
    'VALENTINO', 'BALENCIAGA', 'CHANEL', 'TIFFANY',
    'JIMMY CHOO', 'DIOR', 'HERMÈS', 'ALEXANDER MCQUEEN',
    'GUCCI', 'PRADA', 'CARTIER', 'BULGARI',
  ][i],
  category: [
    'Vestidos', 'Blazers', 'Bolsas', 'Joias',
    'Sapatos', 'Acessórios', 'Acessórios', 'Calças',
    'Jaquetas', 'Saias', 'Joias', 'Joias',
  ][i],
  imageUrls: [],
  basePrice: [1290, 2450, 8900, 3200, 1750, 2100, 4500, 1890, 5600, 1340, 12500, 7800][i].toDouble(),
  discountPrice: i % 4 == 0 ? [1290, 2450, 8900, 3200, 1750, 2100, 4500, 1890, 5600, 1340, 12500, 7800][i] * 0.8 : null,
  variants: [],
  isActive: true,
));

final _filterCategories = ['Todos', 'Roupas', 'Bolsas', 'Joias', 'Sapatos', 'Acessórios'];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Todos';
  RangeValues _priceRange = const RangeValues(0, 15000);
  bool _showFilters = false;

  List<Product> get _filteredProducts {
    return _mockProducts.where((p) {
      if (_selectedCategory != 'Todos') {
        final catMap = {
          'Roupas': ['Vestidos', 'Blazers', 'Calças', 'Jaquetas', 'Saias'],
          'Bolsas': ['Bolsas'],
          'Joias': ['Joias'],
          'Sapatos': ['Sapatos'],
          'Acessórios': ['Acessórios'],
        };
        if (!(catMap[_selectedCategory]?.contains(p.category) ?? true)) return false;
      }
      final price = p.discountPrice ?? p.basePrice;
      if (price < _priceRange.start || price > _priceRange.end) return false;
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        backgroundColor: ZoeColors.surface,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: ZoeColors.cream,
            borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar marcas, produtos...',
              hintStyle: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
              prefixIcon: const Icon(Icons.search, color: ZoeColors.mediumGray, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: ZoeTypography.bodyMedium,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? ZoeColors.primary : ZoeColors.charcoal,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ZoeSpacing.pagePadding, vertical: 8),
              itemCount: _filterCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _filterCategories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? ZoeColors.secondary : ZoeColors.surface,
                      borderRadius: BorderRadius.circular(ZoeSpacing.radiusFull),
                      border: Border.all(
                        color: isSelected ? ZoeColors.secondary : ZoeColors.lightGray,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: ZoeTypography.labelSmall.copyWith(
                        color: isSelected ? ZoeColors.white : ZoeColors.darkGray,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Price filter
          if (_showFilters)
            Container(
              padding: const EdgeInsets.fromLTRB(ZoeSpacing.pagePadding, 0, ZoeSpacing.pagePadding, ZoeSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Faixa de preço', style: ZoeTypography.labelSmall.copyWith(color: ZoeColors.darkGray)),
                      Text(
                        'R\$ ${_priceRange.start.round()} — R\$ ${_priceRange.end.round()}',
                        style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 15000,
                    divisions: 30,
                    activeColor: ZoeColors.primary,
                    inactiveColor: ZoeColors.lightGray,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZoeSpacing.pagePadding, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'resultado' : 'resultados'}',
                  style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: ZoeColors.lightGray),
                        const SizedBox(height: 16),
                        Text('Nenhum resultado encontrado', style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, i) {
                      final product = _filteredProducts[i];
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
                              Expanded(
                                flex: 5,
                                child: Hero(
                                  tag: 'product-${product.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ZoeColors.cream,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(ZoeSpacing.radiusMd)),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(child: Icon(_catIcon(product.category), color: ZoeColors.primaryLight, size: 48)),
                                        if (hasDiscount)
                                          Positioned(
                                            top: 8, left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: ZoeColors.accent, borderRadius: BorderRadius.circular(4)),
                                              child: Text('-${((1 - product.discountPrice! / product.basePrice) * 100).round()}%',
                                                style: const TextStyle(color: ZoeColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                      ],
                                    ),
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
                                      Text(product.name, style: ZoeTypography.bodyMedium.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const Spacer(),
                                      if (hasDiscount) ...[
                                        Text('R\$ ${product.basePrice.toStringAsFixed(2)}', style: ZoeTypography.priceStrikethrough.copyWith(fontSize: 12)),
                                        Text('R\$ ${product.discountPrice!.toStringAsFixed(2)}', style: ZoeTypography.priceMedium.copyWith(fontSize: 15, color: ZoeColors.accent)),
                                      ] else
                                        Text('R\$ ${product.basePrice.toStringAsFixed(2)}', style: ZoeTypography.priceMedium.copyWith(fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 300.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'vestidos': case 'blazers': case 'calças': case 'jaquetas': case 'saias': return Icons.checkroom;
      case 'bolsas': return Icons.shopping_bag;
      case 'joias': return Icons.diamond;
      case 'sapatos': return Icons.straighten;
      default: return Icons.auto_awesome;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
