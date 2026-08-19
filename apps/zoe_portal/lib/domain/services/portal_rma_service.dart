import 'package:zoe_portal/domain/entities/portal_rma.dart';

/// Contrato do serviço de devoluções (RMA) do Portal.
abstract class PortalRmaService {
  /// Lista solicitações de RMA com filtro opcional por [status].
  Future<List<PortalRma>> getRmaRequests({String? status});

  /// Atualiza o status de uma solicitação de RMA.
  Future<void> updateRmaStatus(String id, String status);
}
