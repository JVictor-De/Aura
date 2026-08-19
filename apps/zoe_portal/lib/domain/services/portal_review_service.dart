import 'package:zoe_portal/domain/entities/portal_review.dart';

/// Contrato do serviço de avaliações do Portal.
abstract class PortalReviewService {
  /// Lista avaliações com filtro opcional por [status].
  Future<List<PortalReview>> getReviews({String? status});

  /// Modera uma avaliação, definindo seu status como `approved` ou
  /// `rejected`.
  Future<void> moderateReview(String id, String status);
}
