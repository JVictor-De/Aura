import 'package:zoe_portal/domain/entities/portal_coupon.dart';

/// Contrato do serviço de cupons do Portal.
abstract class PortalCouponService {
  /// Lista todos os cupons da loja.
  Future<List<PortalCoupon>> getCoupons();

  /// Cria um novo cupom a partir de [data].
  Future<PortalCoupon> createCoupon(Map<String, dynamic> data);

  /// Remove um cupom pelo [id].
  Future<void> deleteCoupon(String id);

  /// Ativa ou desativa um cupom.
  Future<void> toggleCoupon(String id, bool isActive);
}
