/// Implementação do ProductService usando Dio.
///
/// Referências:
/// - ARCHITECTURE.md §data/repositories
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/result.dart';
import '../../domain/services/product_service.dart';

class ProductServiceImpl implements ProductService {
  final Dio _dio;

  ProductServiceImpl(this._dio);

  @override
  Future<Result<List<Product>>> getProducts({
    String? storeId,
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (storeId != null) params['store_id'] = storeId;
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: params,
      );

      final items = (response.data['items'] as List? ?? response.data as List)
          .map((json) => _productFromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Failed to load products',
      ));
    }
  }

  @override
  Future<Result<Product>> getProductById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.products}/$id');
      return Result.success(_productFromJson(response.data));
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Product not found',
      ));
    }
  }

  @override
  Future<Result<List<Product>>> searchProducts({
    String query = '',
    String? category,
    String? storeId,
    double? minPrice,
    double? maxPrice,
    String? brand,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (query.isNotEmpty) params['q'] = query;
      if (category != null) params['category'] = category;
      if (storeId != null) params['store_id'] = storeId;
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;
      if (brand != null) params['brand'] = brand;

      final response = await _dio.get(
        '${ApiEndpoints.products}/search',
        queryParameters: params,
      );

      final items = (response.data['items'] as List? ?? response.data as List)
          .map((json) => _productFromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return Result.error(ServerFailure(
        e.response?.data?['detail'] ?? 'Search failed',
      ));
    }
  }

  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      variants: (json['variants'] as List? ?? [])
          .map((v) => _variantFromJson(v as Map<String, dynamic>))
          .toList(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  SkuVariant _variantFromJson(Map<String, dynamic> json) {
    return SkuVariant(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      size: json['size'] as String,
      color: json['color'] as String,
      colorHex: json['color_hex'] as String? ?? '#000000',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}
