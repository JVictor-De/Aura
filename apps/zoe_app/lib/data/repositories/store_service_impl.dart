/// Implementação do StoreService usando Dio.
///
/// Referências:
/// - ARCHITECTURE.md §2.1: Geolocalização-First
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/store_service.dart';

class StoreServiceImpl implements StoreService {
  final Dio _dio;

  StoreServiceImpl(this._dio);

  @override
  Future<Result<List<Store>>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.stores,
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        },
      );

      final items = (response.data as List)
          .map((json) => _storeFromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to load stores',
      ));
    }
  }

  @override
  Future<Result<Store>> getStoreById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.stores}/$id');
      return Result.success(_storeFromJson(response.data));
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Store not found',
      ));
    }
  }

  @override
  Future<Result<List<Store>>> searchStores(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.stores,
        queryParameters: {'search': query},
      );

      final items = (response.data as List)
          .map((json) => _storeFromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Search failed',
      ));
    }
  }

  Store _storeFromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      estimatedDeliveryTime: json['estimated_delivery_time'] as String?,
    );
  }
}
