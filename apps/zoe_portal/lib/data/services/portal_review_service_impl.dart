import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/portal_review.dart';
import 'package:zoe_portal/domain/services/portal_review_service.dart';

/// Implementação de [PortalReviewService] usando Dio.
class PortalReviewServiceImpl implements PortalReviewService {
  final Dio _dio;

  PortalReviewServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PortalReview>> getReviews({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/reviews',
        queryParameters: queryParams,
      );

      final list = response.data as List<dynamic>;
      return list
          .map((e) => PortalReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load reviews');
    }
  }

  @override
  Future<void> moderateReview(String id, String status) async {
    try {
      await _dio.patch(
        '/reviews/$id/moderate',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to moderate review');
    }
  }
}
