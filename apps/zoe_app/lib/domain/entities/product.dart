/// Entidade Product do domínio.
///
/// Referência: ARCHITECTURE.md §Product Entity
class Product {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String brand;
  final String category;
  final List<String> imageUrls;
  final double basePrice;
  final double? discountPrice;
  final List<SkuVariant> variants;
  final bool isActive;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.brand,
    required this.category,
    required this.imageUrls,
    required this.basePrice,
    this.discountPrice,
    required this.variants,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => SkuVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'description': description,
        'brand': brand,
        'category': category,
        'image_urls': imageUrls,
        'base_price': basePrice,
        'discount_price': discountPrice,
        'variants': variants.map((v) => v.toJson()).toList(),
        'is_active': isActive,
      };
}

/// Referência: ARCHITECTURE.md §SkuVariant
class SkuVariant {
  final String id;
  final String sku;
  final String size;
  final String color;
  final String colorHex;
  final int stockQuantity;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const SkuVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    required this.colorHex,
    required this.stockQuantity,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  factory SkuVariant.fromJson(Map<String, dynamic> json) {
    return SkuVariant(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      size: json['size'] as String,
      color: json['color'] as String,
      colorHex: json['color_hex'] as String? ?? '#000000',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'size': size,
        'color': color,
        'color_hex': colorHex,
        'stock_quantity': stockQuantity,
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };
}
