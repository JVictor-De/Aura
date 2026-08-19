/// Contrato do PaymentService.
///
/// Referência: ARCHITECTURE.md §ERD: PAYMENTS / PAYMENT_EVENTS
import '../entities/payment_method.dart';
import '../repositories/result.dart';

abstract class PaymentService {
  /// Retorna os métodos de pagamento salvos do usuário.
  Future<Result<List<PaymentMethod>>> getPaymentMethods();

  /// Adiciona um novo método de pagamento.
  Future<Result<PaymentMethod>> addPaymentMethod(Map<String, dynamic> data);

  /// Remove um método de pagamento.
  Future<Result<void>> removePaymentMethod(String id);

  /// Define um método de pagamento como padrão.
  Future<Result<void>> setDefaultPaymentMethod(String id);

  /// Processa o pagamento de um pedido.
  /// Retorna o ID da transação criada.
  Future<Result<String>> processPayment({
    required String orderId,
    required String paymentMethodId,
    required String method, // credit_card, debit_card, pix
    required double amount,
    required String idempotencyKey,
  });

  /// Consulta o status de um pagamento.
  Future<Result<Map<String, dynamic>>> getPaymentStatus(String paymentId);
}
