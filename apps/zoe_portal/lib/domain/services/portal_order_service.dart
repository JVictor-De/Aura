import 'package:zoe_portal/domain/entities/portal_order.dart';

/// Contrato do serviço de pedidos do Portal.
abstract class PortalOrderService {
  /// Lista pedidos com filtro opcional por [status].
  Future<List<PortalOrder>> getOrders({String? status});

  /// Retorna os detalhes de um envio específico.
  Future<PortalOrder> getOrderDetail(String shipmentId);

  /// Atualiza o status de um envio.
  Future<void> updateOrderStatus(String shipmentId, String status);
}
