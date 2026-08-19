import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/portal_order.dart';
import 'package:zoe_portal/domain/services/portal_order_service.dart';

/// Implementação de [PortalOrderService] usando Dio.
class PortalOrderServiceImpl implements PortalOrderService {
  final Dio _dio;

  PortalOrderServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PortalOrder>> getOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/orders',
        queryParameters: queryParams,
      );

      final list = response.data as List<dynamic>;
      return list
          .map((e) => PortalOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load orders');
    }
  }

  @override
  Future<PortalOrder> getOrderDetail(String shipmentId) async {
    try {
      final response = await _dio.get('/orders/$shipmentId');
      return PortalOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load order detail');
    }
  }

  @override
  Future<void> updateOrderStatus(String shipmentId, String status) async {
    try {
      await _dio.patch(
        '/orders/$shipmentId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update order status');
    }
  }
}
