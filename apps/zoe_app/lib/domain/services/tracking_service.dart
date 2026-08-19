/// Contrato do TrackingService.
///
/// Referência: ARCHITECTURE.md §2.3: Rastreamento em Tempo Real
import '../entities/tracking.dart';
import '../repositories/result.dart';

abstract class TrackingService {
  /// Obtém o status de rastreamento de um pedido via HTTP (polling fallback).
  Future<Result<DeliveryTracking>> getTrackingStatus(String orderId);

  /// Atualiza a localização do motorista (usado pelo app do motorista).
  Future<Result<void>> updateDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
  });
}
