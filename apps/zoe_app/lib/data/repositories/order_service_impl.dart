/// Implementação do OrderService usando Dio.
///
/// Referências:
/// - ARCHITECTURE.md §Checkout Saga
/// - TECHNICAL_AUDIT.md §F-1: Checkout Saga Flow
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/order_service.dart';

class OrderServiceImpl implements OrderService {
  final Dio _dio;

  OrderServiceImpl(this._dio);

  @override
  Future<Result<Order>> createOrder({
    List<CartItem>? items,
    String? addressId,
    String? deliveryAddressId,
    String? paymentMethod,
    String? couponCode,
    String? idempotencyKey,
  }) async {
    final effectiveAddressId = deliveryAddressId ?? addressId ?? '';
    final key = idempotencyKey ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final response = await _dio.post(
        ApiEndpoints.orders,
        data: {
          'delivery_address_id': effectiveAddressId,
          if (couponCode != null) 'coupon_code': couponCode,
          if (paymentMethod != null) 'payment_method': paymentMethod,
        },
        options: Options(headers: {
          'X-Idempotency-Key': key,
        }),
      );
      return Result.success(_orderFromJson(response.data));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data?['detail'] ?? '';

      if (status == 409 && detail.toString().contains('stock')) {
        return Result.error(const StockUnavailableFailure());
      }
      if (status == 409 && detail.toString().contains('price')) {
        return Result.error(const PriceChangedFailure());
      }
      return Result.error(ServerFailure(detail.toString()));
    }
  }

  @override
  Future<Result<List<Order>>> getOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );

      final items = (response.data as List)
          .map((json) => _orderFromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to load orders',
      ));
    }
  }

  @override
  Future<Result<Order>> getOrderById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.orders}/$id');
      return Result.success(_orderFromJson(response.data));
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Order not found',
      ));
    }
  }

  Order _orderFromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      couponCode: json['coupon_code'] as String?,
      deliveryAddressId: json['delivery_address_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      shipments: (json['shipments'] as List? ?? [])
          .map((s) => _shipmentFromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  OrderShipment _shipmentFromJson(Map<String, dynamic> json) {
    return OrderShipment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      storeId: json['store_id'] as String,
      storeName: json['store_name'] as String? ?? '',
      status: json['status'] as String,
      trackingCode: json['tracking_code'] as String?,
      items: (json['items'] as List? ?? [])
          .map((i) => _orderItemFromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  OrderItem _orderItemFromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      variantId: json['variant_id'] as String,
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }
}
