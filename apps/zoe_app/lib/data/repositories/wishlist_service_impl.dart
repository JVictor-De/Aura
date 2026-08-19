/// Implementação do WishlistService via Dio.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/wishlist_service.dart';

class WishlistServiceImpl implements WishlistService {
  final Dio _dio;

  WishlistServiceImpl(this._dio);

  @override
  Future<Result<List<WishlistItem>>> getWishlist() async {
    try {
      final response = await _dio.get(ApiEndpoints.wishlists);
      final list = (response.data as List)
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(list);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao carregar favoritos'));
    }
  }

  @override
  Future<Result<void>> addToWishlist(String productId) async {
    try {
      await _dio.post(ApiEndpoints.wishlists, data: {'product_id': productId});
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao adicionar favorito'));
    }
  }

  @override
  Future<Result<void>> removeFromWishlist(String productId) async {
    try {
      await _dio.delete('${ApiEndpoints.wishlists}/$productId');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao remover favorito'));
    }
  }
}
