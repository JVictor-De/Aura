/// Implementação do PaymentService via Dio.
///
/// Referência: ARCHITECTURE.md §ERD: PAYMENTS
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  final Dio _dio;

  PaymentServiceImpl(this._dio);

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods() async {
    try {
      final response = await _dio.get('${ApiEndpoints.payments}/methods');
      final list = (response.data as List)
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(list);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao carregar métodos de pagamento'),
      );
    }
  }

  @override
  Future<Result<PaymentMethod>> addPaymentMethod(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.payments}/methods',
        data: data,
      );
      return Result.success(
        PaymentMethod.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao adicionar método de pagamento'),
      );
    }
  }

  @override
  Future<Result<void>> removePaymentMethod(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.payments}/methods/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao remover método de pagamento'),
      );
    }
  }

  @override
  Future<Result<void>> setDefaultPaymentMethod(String id) async {
    try {
      await _dio.patch('${ApiEndpoints.payments}/methods/$id/default');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao definir método padrão'),
      );
    }
  }

  @override
  Future<Result<String>> processPayment({
    required String orderId,
    required String paymentMethodId,
    required String method,
    required double amount,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.payments,
        data: {
          'order_id': orderId,
          'payment_method_id': paymentMethodId,
          'method': method,
          'amount': amount,
        },
        options: Options(
          headers: {'X-Idempotency-Key': idempotencyKey},
        ),
      );
      final txId = (response.data as Map<String, dynamic>)['id'] as String;
      return Result.success(txId);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao processar pagamento'),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await _dio.get('${ApiEndpoints.payments}/$paymentId');
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.error(
        ServerFailure(e.message ?? 'Erro ao consultar pagamento'),
      );
    }
  }
}
