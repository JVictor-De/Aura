/// Contrato do RmaService.
///
/// Referência: ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
import '../entities/rma_request.dart';
import '../repositories/result.dart';

abstract class RmaService {
  Future<Result<bool>> checkEligibility(String orderId);
  Future<Result<RmaRequest>> createRmaRequest({
    required String orderId,
    required List<RmaItem> items,
    required String resolutionType,
  });
  Future<Result<List<RmaRequest>>> getRmaRequests();
}
