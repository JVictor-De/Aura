/// Utilitário de permissões de localização.
///
/// Referências:
/// - ARCHITECTURE.md §2.1: Geolocalização-First
/// - prompt.md §3.1: geolocator
import 'package:geolocator/geolocator.dart';

class PermissionsHelper {
  /// Solicita e verifica permissão de localização.
  /// Retorna a posição atual ou null se negada.
  static Future<Position?> requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Verifica se já tem permissão sem solicitar.
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
