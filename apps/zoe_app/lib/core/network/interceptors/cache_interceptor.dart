/// Interceptor de cache em memória para GET requests.
///
/// Referências:
/// - ARCHITECTURE.md §Interceptors: CacheInterceptor
/// - TECHNICAL_AUDIT.md §2.3: TTL de cache para catálogo
import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  final Map<String, _CacheEntry> _cache = {};
  final Duration ttl;

  CacheInterceptor({this.ttl = const Duration(minutes: 5)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      return handler.next(options);
    }

    final key = '${options.uri}';
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      // Retorna do cache
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: entry.data,
        ),
        true,
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' &&
        response.statusCode == 200) {
      final key = '${response.requestOptions.uri}';
      _cache[key] = _CacheEntry(
        data: response.data,
        expiry: DateTime.now().add(ttl),
      );
    }
    handler.next(response);
  }

  /// Limpa todo o cache (útil em logout ou pull-to-refresh).
  void clearCache() => _cache.clear();

  /// Remove entrada específica do cache.
  void invalidate(String url) => _cache.remove(url);
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
