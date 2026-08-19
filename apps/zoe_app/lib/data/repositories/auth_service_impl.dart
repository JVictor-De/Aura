/// Implementação do AuthService usando Dio.
///
/// Referências:
/// - ARCHITECTURE.md §data/repositories: implementações concretas
/// - prompt.md §3.1: dio + flutter_secure_storage
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/auth_service.dart';

class AuthServiceImpl implements AuthService {
  final Dio _dio;
  final SecureStorage _storage;

  AuthServiceImpl(this._dio, this._storage);

  @override
  Future<Result<AuthTokens>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final tokens = AuthTokens.fromJson(response.data);
      await _storage.setAccessToken(tokens.accessToken);
      await _storage.setRefreshToken(tokens.refreshToken);
      await _storage.setUserId(tokens.userId);
      return Result.success(tokens);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Login failed',
      ));
    }
  }

  @override
  Future<Result<AuthTokens>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
      final tokens = AuthTokens.fromJson(response.data);
      await _storage.setAccessToken(tokens.accessToken);
      await _storage.setRefreshToken(tokens.refreshToken);
      return Result.success(tokens);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Registration failed',
      ));
    }
  }

  @override
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data);
      await _storage.setAccessToken(tokens.accessToken);
      await _storage.setRefreshToken(tokens.refreshToken);
      return Result.success(tokens);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Token refresh failed',
      ));
    }
  }

  @override
  Future<Result<UserProfile>> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return Result.success(UserProfile.fromJson(response.data));
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to load profile',
      ));
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clearAll();
  }
}
