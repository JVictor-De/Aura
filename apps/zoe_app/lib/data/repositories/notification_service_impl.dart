/// Implementação do NotificationService via Dio.
///
/// Gerencia tokens de push notification no backend.
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../domain/services/notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  final Dio _dio;

  NotificationServiceImpl(this._dio);

  @override
  Future<void> registerToken(String token, String platform) async {
    try {
      await _dio.post('${ApiEndpoints.notifications}/token', data: {
        'token': token,
        'platform': platform,
      });
    } on DioException catch (_) {
      // Silently fail — token registration is best-effort
    }
  }

  @override
  Future<void> deactivateToken(String token) async {
    try {
      await _dio.delete('${ApiEndpoints.notifications}/token', data: {
        'token': token,
      });
    } on DioException catch (_) {
      // Silently fail
    }
  }

  @override
  Future<bool> requestPermission() async {
    // Web: use Notification API via JS interop
    // For now, return true (permission handled at platform level)
    return true;
  }

  @override
  Future<String?> getDeviceToken() async {
    // Web: FCM can provide token via firebase_messaging
    // Stub — return null until Firebase is configured
    return null;
  }
}
