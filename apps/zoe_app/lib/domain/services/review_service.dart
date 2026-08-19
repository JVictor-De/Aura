/// Contrato do ReviewService.
///
/// Referência: ARCHITECTURE.md §2.5: Social Proof (Reviews)
import '../entities/review.dart';
import '../repositories/result.dart';

abstract class ReviewService {
  Future<Result<List<Review>>> getProductReviews(String productId);
  Future<Result<ReviewSummary>> getProductRatingSummary(String productId);
  Future<Result<Review>> createReview({
    required String productId,
    required String orderId,
    required int ratingProduct,
    required int ratingDelivery,
    String? comment,
  });
}
