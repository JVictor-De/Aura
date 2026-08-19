/// Idempotency Interceptor: injeta X-Idempotency-Key automaticamente
/// em chamadas críticas (POST/PUT/PATCH para /orders e /payments).
///
/// Referências:
/// - TECHNICAL_AUDIT.md §1.1 Race Conditions:
///   "Usar chave de idempotência em cada requisição"
///   "Implementar X-Idempotency-Key em chamadas críticas"
/// - ARCHITECTURE.md §Headers Obrigatórios:
///   "X-Idempotency-Key: obrigatório para POST/PATCH em /orders e /payments"
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  static const _uuid = Uuid();

  /// Rotas que recebem X-Idempotency-Key automaticamente
  static const _criticalPaths = ['/orders', '/payments'];

  /// Métodos que exigem idempotência
  static const _criticalMethods = ['POST', 'PUT', 'PATCH'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isCriticalMethod = _criticalMethods.contains(
      options.method.toUpperCase(),
    );
    final isCriticalPath = _criticalPaths.any(
      (path) => options.path.contains(path),
    );

    if (isCriticalMethod && isCriticalPath) {
      // Só adicionar se não foi fornecido manualmente
      options.headers['X-Idempotency-Key'] ??= _uuid.v4();
    }

    handler.next(options);
  }
}
