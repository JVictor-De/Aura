/// Entidade Review do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: REVIEWS
class Review {
  final String id;
  final String userId;
  final String productId;
  final String orderId;
  final int ratingProduct; // 1-5
  final int ratingDelivery; // 1-5
  final String? comment;
  final bool isVisible;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.ratingProduct,
    required this.ratingDelivery,
    this.comment,
    this.isVisible = true,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      orderId: json['order_id'] as String,
      ratingProduct: json['rating_product'] as int,
      ratingDelivery: json['rating_delivery'] as int,
      comment: json['comment'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_id': productId,
        'order_id': orderId,
        'rating_product': ratingProduct,
        'rating_delivery': ratingDelivery,
        'comment': comment,
        'is_visible': isVisible,
        'created_at': createdAt.toIso8601String(),
      };
}

class ReviewSummary {
  final double avgProduct;
  final double avgDelivery;
  final int totalReviews;

  const ReviewSummary({
    required this.avgProduct,
    required this.avgDelivery,
    required this.totalReviews,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      avgProduct: (json['avg_product'] as num).toDouble(),
      avgDelivery: (json['avg_delivery'] as num).toDouble(),
      totalReviews: json['total_reviews'] as int,
    );
  }
}
