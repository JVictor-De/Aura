/// Abstração de armazenamento seguro (tokens JWT).
///
/// Referências:
/// - ARCHITECTURE.md §Interceptors: AuthInterceptor lê token do storage
/// - prompt.md §3.1: flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // ── Access Token ──────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  // ── Refresh Token ─────────────────────────────────────────
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  // ── User ID ───────────────────────────────────────────────
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> setUserId(String id) =>
      _storage.write(key: _userIdKey, value: id);

  // ── Logout ────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}
