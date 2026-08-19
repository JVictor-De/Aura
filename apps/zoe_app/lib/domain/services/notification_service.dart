/// Contrato do NotificationService.
///
/// Referência: ARCHITECTURE.md §2.6: Notificações (Push + In-App)
abstract class NotificationService {
  Future<void> registerToken(String token, String platform);
  Future<void> deactivateToken(String token);
  Future<bool> requestPermission();
  Future<String?> getDeviceToken();
}
