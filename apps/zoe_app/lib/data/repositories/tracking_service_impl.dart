/// Implementação do TrackingService via Dio (HTTP polling fallback).
///
/// Referência: ARCHITECTURE.md §2.3: Rastreamento em Tempo Real
/// O WebSocket primário é gerenciado pelo TrackingCubit.
/// Este service cobre o fallback HTTP e consultas pontuais.
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/tracking.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/tracking_service.dart';

class TrackingServiceImpl implements TrackingService {
  final Dio _dio;

  TrackingServiceImpl(this._dio);

  @override
  Future<Result<DeliveryTracking>> getTrackingStatus(String orderId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.orders}/$orderId/tracking',
      );
      return Result.success(
        DeliveryTracking.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao obter rastreamento'),
      );
    }
  }

  @override
  Future<Result<void>> updateDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _dio.patch(
        '${ApiEndpoints.orders}/$orderId/tracking',
        data: {
          'current_lat': lat,
          'current_lng': lng,
        },
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao atualizar localização'),
      );
    }
  }
}
