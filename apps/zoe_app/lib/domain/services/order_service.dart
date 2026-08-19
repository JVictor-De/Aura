/// Contrato do OrderService (Facade pattern).
///
/// Referências:
/// - ARCHITECTURE.md §Checkout Saga
/// - TECHNICAL_AUDIT.md §F-1: Checkout Saga
import '../entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/result.dart';

abstract class OrderService {
  /// Cria pedido a partir do carrinho atual.
  /// Executa: validar preços → reservar estoque → criar pedido → pagamento.
  Future<Result<Order>> createOrder({
    List<CartItem>? items,
    String? addressId,
    String? deliveryAddressId,
    String? paymentMethod,
    String? couponCode,
    String? idempotencyKey,
  });

  Future<Result<List<Order>>> getOrders({int page = 1, int limit = 20});

  Future<Result<Order>> getOrderById(String id);
}
