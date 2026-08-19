/// Entidade PortalReview do domínio (visão lojista).
///
/// Representa uma avaliação de produto feita por um cliente após a entrega.
/// O lojista pode moderar (aprovar/rejeitar) avaliações pelo painel.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist (Favoritos) e Social Proof (Reviews)
/// Referência: ARCHITECTURE.md §ERD: REVIEWS
class PortalReview {
  /// Identificador único da avaliação.
  final String id;

  /// Identificador do produto avaliado.
  final String productId;

  /// Nome do produto avaliado (desnormalizado para exibição rápida).
  final String productName;

  /// Nome do cliente que escreveu a avaliação.
  final String customerName;

  /// Nota de 1 a 5 estrelas.
  final int rating;

  /// Comentário textual do cliente (opcional).
  final String? comment;

  /// Status de moderação: `pending`, `approved`, `rejected`.
  final String status;

  /// Data/hora em que a avaliação foi criada.
  final DateTime createdAt;

  const PortalReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalReview.fromJson(Map<String, dynamic> json) {
    return PortalReview(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      customerName: json['customer_name'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'customer_name': customerName,
        'rating': rating,
        'comment': comment,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
