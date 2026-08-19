/// Entidade Order do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: ORDERS, ORDER_SHIPMENTS
class Order {
  final String id;
  final String userId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String deliveryAddressId;
  final DateTime createdAt;
  final List<OrderShipment> shipments;

  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.total,
    this.couponCode,
    required this.deliveryAddressId,
    required this.createdAt,
    required this.shipments,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total_amount'] as num).toDouble(),
      couponCode: json['coupon_code'] as String?,
      deliveryAddressId: json['delivery_address_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      shipments: (json['shipments'] as List<dynamic>?)
              ?.map((e) => OrderShipment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'status': status,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount_amount': discount,
        'total_amount': total,
        'coupon_code': couponCode,
        'delivery_address_id': deliveryAddressId,
        'created_at': createdAt.toIso8601String(),
        'shipments': shipments.map((s) => s.toJson()).toList(),
      };
}

class OrderShipment {
  final String id;
  final String orderId;
  final String storeId;
  final String storeName;
  final String status;
  final String? trackingCode;
  final List<OrderItem> items;

  const OrderShipment({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.status,
    this.trackingCode,
    required this.items,
  });

  factory OrderShipment.fromJson(Map<String, dynamic> json) {
    return OrderShipment(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? '',
      storeId: json['store_id'] as String,
      storeName: json['store_name'] as String? ?? '',
      status: json['status'] as String,
      trackingCode: json['tracking_code'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'store_id': storeId,
        'store_name': storeName,
        'status': status,
        'tracking_code': trackingCode,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String variantId;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      variantId: json['variant_id'] as String? ?? json['sku_variant_id'] as String? ?? '',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'variant_id': variantId,
        'size': size,
        'color': color,
        'quantity': quantity,
        'unit_price': unitPrice,
        'image_url': imageUrl,
      };
}
