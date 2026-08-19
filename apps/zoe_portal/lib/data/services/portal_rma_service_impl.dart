import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/portal_rma.dart';
import 'package:zoe_portal/domain/services/portal_rma_service.dart';

/// Implementação de [PortalRmaService] usando Dio.
class PortalRmaServiceImpl implements PortalRmaService {
  final Dio _dio;

  PortalRmaServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PortalRma>> getRmaRequests({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/returns',
        queryParameters: queryParams,
      );

      final list = response.data as List<dynamic>;
      return list
          .map((e) => PortalRma.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load RMA requests');
    }
  }

  @override
  Future<void> updateRmaStatus(String id, String status) async {
    try {
      await _dio.patch(
        '/returns/$id/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update RMA status');
    }
  }
}
