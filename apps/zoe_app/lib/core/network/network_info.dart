/// Verifica conectividade de rede.
///
/// Referências:
/// - ARCHITECTURE.md §Corner Cases: offline-first behavior
/// - TECHNICAL_AUDIT.md §1.4: fallback polling quando WS offline
import 'dart:io';

class NetworkInfo {
  /// Verifica se o dispositivo tem conectividade.
  /// Faz um lookup DNS simples como heurística.
  static Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
