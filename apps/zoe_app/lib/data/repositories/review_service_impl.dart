/// Implementação do ReviewService via Dio.
///
/// Referência: ARCHITECTURE.md §2.5: Social Proof (Reviews)
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/review_service.dart';

class ReviewServiceImpl implements ReviewService {
  final Dio _dio;

  ReviewServiceImpl(this._dio);

  @override
  Future<Result<List<Review>>> getProductReviews(String productId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.reviews}/product/$productId');
      final list = (response.data as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(list);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao carregar avaliações'));
    }
  }

  @override
  Future<Result<ReviewSummary>> getProductRatingSummary(String productId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.reviews}/product/$productId/summary');
      return Result.success(ReviewSummary.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao carregar resumo'));
    }
  }

  @override
  Future<Result<Review>> createReview({
    required String productId,
    required String orderId,
    required int ratingProduct,
    required int ratingDelivery,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.reviews, data: {
        'product_id': productId,
        'order_id': orderId,
        'rating_product': ratingProduct,
        'rating_delivery': ratingDelivery,
        'comment': comment,
      });
      return Result.success(Review.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao enviar avaliação'));
    }
  }
}
