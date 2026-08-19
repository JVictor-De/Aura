import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zoe_portal/domain/services/portal_auth_service.dart';

/// Implementação de [PortalAuthService] usando Dio + SharedPreferences.
class PortalAuthServiceImpl implements PortalAuthService {
  final Dio _dio;
  final SharedPreferences _prefs;

  PortalAuthServiceImpl({
    required Dio dio,
    required SharedPreferences prefs,
  })  : _dio = dio,
        _prefs = prefs;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      // Persist tokens locally
      if (data['access_token'] != null) {
        await _prefs.setString('access_token', data['access_token'] as String);
      }
      if (data['refresh_token'] != null) {
        await _prefs.setString(
            'refresh_token', data['refresh_token'] as String);
      }
      if (data['user_id'] != null) {
        await _prefs.setString('user_id', data['user_id'] as String);
      }
      if (data['role'] != null) {
        await _prefs.setString('role', data['role'] as String);
      }
      if (data['store_id'] != null) {
        await _prefs.setString('store_id', data['store_id'] as String);
      }

      return data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('user_id');
    await _prefs.remove('role');
    await _prefs.remove('store_id');
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = _prefs.getString('access_token');
    if (token == null) return null;

    try {
      final response = await _dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return null;
      }
      throw Exception(e.message ?? 'Failed to fetch current user');
    }
  }
}
