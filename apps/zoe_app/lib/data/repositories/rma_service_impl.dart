/// Implementação do RmaService via Dio.
///
/// Referência: ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/rma_request.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/rma_service.dart';

class RmaServiceImpl implements RmaService {
  final Dio _dio;

  RmaServiceImpl(this._dio);

  @override
  Future<Result<bool>> checkEligibility(String orderId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.rma}/eligibility/$orderId');
      final data = response.data as Map<String, dynamic>;
      return Result.success(data['eligible'] as bool? ?? false);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao verificar elegibilidade'));
    }
  }

  @override
  Future<Result<RmaRequest>> createRmaRequest({
    required String orderId,
    required List<RmaItem> items,
    required String resolutionType,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.rma, data: {
        'order_id': orderId,
        'resolution_type': resolutionType,
        'items': items.map((i) => i.toJson()).toList(),
      });
      return Result.success(RmaRequest.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao criar devolução'));
    }
  }

  @override
  Future<Result<List<RmaRequest>>> getRmaRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.rma);
      final list = (response.data as List)
          .map((e) => RmaRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(list);
    } on DioException catch (e) {
      return Result.error(ServerFailure(e.message ?? 'Erro ao carregar devoluções'));
    }
  }
}
