/// Auth Interceptor: injeta JWT e renova automaticamente se expirado.
///
/// Referências:
/// - TECHNICAL_AUDIT.md §1.4: renovação automática de JWT (refresh)
/// - ARCHITECTURE.md §core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  Dio? _refreshDio; // Dio separado para refresh (evita loop)

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Se 401, tenta renovar o token (TECHNICAL_AUDIT §1.4)
    if (err.response?.statusCode == 401) {
      try {
        final newTokens = await _refreshAccessToken();
        if (newTokens != null) {
          // Salvar novos tokens
          await _storage.write(key: _accessTokenKey, value: newTokens['access_token']);

          // Repetir o request original com novo token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer ${newTokens['access_token']}';

          _refreshDio ??= Dio(BaseOptions(baseUrl: opts.baseUrl));
          final response = await _refreshDio!.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh falhou → forçar logout
      }
    }
    handler.next(err);
  }

  Future<Map<String, dynamic>?> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    _refreshDio ??= Dio();
    try {
      final response = await _refreshDio!.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Salvar tokens após login/registro
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Limpar tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
