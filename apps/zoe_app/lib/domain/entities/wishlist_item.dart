/// Entidade Wishlist do domínio.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist (Favoritos) e Social Proof
class WishlistItem {
  final String id;
  final String productId;
  final String productName;
  final String brand;
  final double price;
  final double? discountPrice;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.price,
    this.discountPrice,
    this.imageUrl,
    required this.category,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? (json['base_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'brand': brand,
        'price': price,
        'discount_price': discountPrice,
        'image_url': imageUrl,
        'category': category,
        'created_at': createdAt.toIso8601String(),
      };
}
