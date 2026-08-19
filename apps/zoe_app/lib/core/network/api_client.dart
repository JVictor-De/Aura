/// Cliente HTTP (Dio) com interceptores para JWT e idempotência.
///
/// Referências:
/// - TECHNICAL_AUDIT.md §1.1: X-Idempotency-Key automático em chamadas críticas
/// - TECHNICAL_AUDIT.md §1.4: renovação de JWT (refresh) automática
/// - ARCHITECTURE.md §core/network/api_client.dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/idempotency_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
  }) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.addAll([
      authInterceptor,
      IdempotencyInterceptor(),
      ZoeLoggingInterceptor(),
    ]);
  }

  /// Factory para instância padrão
  factory ApiClient.create(AuthInterceptor authInterceptor) {
    return ApiClient(
      baseUrl: EnvConfig.baseUrl,
      authInterceptor: authInterceptor,
    );
  }
}
