/// Implementação do CartService usando Dio para sync com backend.
///
/// Referências:
/// - ARCHITECTURE.md §2.7: Single-Store Cart Isolation
/// - TECHNICAL_AUDIT.md §F-2: Store Conflict
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/cart_service.dart';

class CartServiceImpl implements CartService {
  final Dio _dio;

  CartServiceImpl(this._dio);

  @override
  Future<Result<void>> addToCart(CartItem item) async {
    try {
      await _dio.post(
        '${ApiEndpoints.cart}/items',
        data: {
          'variant_id': item.variantId,
          'quantity': item.quantity,
        },
      );
      return const Result.success(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return Result.error(const StockUnavailableFailure(
          message: 'Item from different store. Clear cart first.',
        ));
      }
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to add to cart',
      ));
    }
  }

  @override
  Future<Result<void>> removeFromCart(String variantId) async {
    try {
      await _dio.delete('${ApiEndpoints.cart}/items/$variantId');
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to remove item',
      ));
    }
  }

  @override
  Future<Result<void>> updateQuantity(String variantId, int quantity) async {
    try {
      await _dio.patch(
        '${ApiEndpoints.cart}/items/$variantId',
        data: {'quantity': quantity},
      );
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to update quantity',
      ));
    }
  }

  @override
  Future<Result<void>> clearCart() async {
    try {
      await _dio.delete(ApiEndpoints.cart);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to clear cart',
      ));
    }
  }

  @override
  Future<Result<void>> clearAndAdd(CartItem item) async {
    try {
      await _dio.post(
        '${ApiEndpoints.cart}/clear-and-add',
        data: {
          'variant_id': item.variantId,
          'quantity': item.quantity,
        },
      );
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to clear and add',
      ));
    }
  }

  @override
  Future<Result<List<CartItem>>> validatePrices() async {
    try {
      final response = await _dio.post('${ApiEndpoints.cart}/validate-prices');
      final changes = response.data['price_changes'] as List? ?? [];

      if (changes.isNotEmpty) {
        return Result.error(const PriceChangedFailure());
      }

      return const Result.success([]);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Price validation failed',
      ));
    }
  }
}
