/// Entidades de Carrinho do domínio.
///
/// Referência: ARCHITECTURE.md §2.7: Single-Store Cart Isolation
class CartItem {
  final String variantId;
  final String productId;
  final String productName;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final String storeId;

  const CartItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    required this.storeId,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity, double? unitPrice}) {
    return CartItem(
      variantId: variantId,
      productId: productId,
      productName: productName,
      size: size,
      color: color,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      imageUrl: imageUrl,
      storeId: storeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'productId': productId,
        'productName': productName,
        'size': size,
        'color': color,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
        'storeId': storeId,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        variantId: json['variantId'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        size: json['size'] as String,
        color: json['color'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        storeId: json['storeId'] as String,
      );
}
