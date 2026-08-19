import 'package:zoe_portal/domain/entities/store_settings.dart';

/// Contrato do serviço de configurações da loja do Portal.
abstract class PortalSettingsService {
  /// Retorna as configurações atuais da loja.
  Future<StoreSettings> getSettings();

  /// Atualiza as configurações da loja.
  Future<StoreSettings> updateSettings(Map<String, dynamic> data);
}
