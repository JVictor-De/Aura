import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/store_settings.dart';
import 'package:zoe_portal/domain/services/portal_settings_service.dart';

/// Implementação de [PortalSettingsService] usando Dio.
class PortalSettingsServiceImpl implements PortalSettingsService {
  final Dio _dio;

  PortalSettingsServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<StoreSettings> getSettings() async {
    try {
      final response = await _dio.get('/stores/settings');
      return StoreSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load store settings');
    }
  }

  @override
  Future<StoreSettings> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/stores/settings', data: data);
      return StoreSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update store settings');
    }
  }
}
