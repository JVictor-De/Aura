/// Logging interceptor para debug de requests/responses.
///
/// Referência: ARCHITECTURE.md §core/network/interceptors/logging_interceptor.dart
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class ZoeLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: 'ZoeHTTP',
    );
    if (options.headers.containsKey('X-Idempotency-Key')) {
      developer.log(
        '  Idempotency-Key: ${options.headers['X-Idempotency-Key']}',
        name: 'ZoeHTTP',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'ZoeHTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.uri}: ${err.message}',
      name: 'ZoeHTTP',
      level: 900,
    );
    handler.next(err);
  }
}
