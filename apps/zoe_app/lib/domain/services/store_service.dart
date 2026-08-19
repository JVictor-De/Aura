/// Contrato do StoreService (Facade pattern).
///
/// Referências:
/// - ARCHITECTURE.md §2.1: Geolocalização-First
import '../entities/store.dart';
import '../repositories/result.dart';

abstract class StoreService {
  /// Busca lojas próximas por coordenadas.
  Future<Result<List<Store>>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  Future<Result<Store>> getStoreById(String id);

  Future<Result<List<Store>>> searchStores(String query);
}
