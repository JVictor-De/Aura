import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/portal_product.dart';
import 'package:zoe_portal/domain/services/portal_inventory_service.dart';

/// Implementação de [PortalInventoryService] usando Dio.
class PortalInventoryServiceImpl implements PortalInventoryService {
  final Dio _dio;

  PortalInventoryServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PortalProduct>> getProducts() async {
    try {
      final response = await _dio.get('/inventory/products');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PortalProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load products');
    }
  }

  @override
  Future<PortalProduct> getProduct(String id) async {
    try {
      final response = await _dio.get('/inventory/products/$id');
      return PortalProduct.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load product');
    }
  }

  @override
  Future<PortalProduct> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/inventory/products', data: data);
      return PortalProduct.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to create product');
    }
  }

  @override
  Future<PortalProduct> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/inventory/products/$id', data: data);
      return PortalProduct.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update product');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete('/inventory/products/$id');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete product');
    }
  }

  @override
  Future<void> updateVariantStock(String variantId, int stock) async {
    try {
      await _dio.patch(
        '/inventory/variants/$variantId/stock',
        data: {'stock': stock},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update variant stock');
    }
  }
}
