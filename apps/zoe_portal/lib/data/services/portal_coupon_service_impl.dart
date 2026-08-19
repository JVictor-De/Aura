import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/portal_coupon.dart';
import 'package:zoe_portal/domain/services/portal_coupon_service.dart';

/// Implementação de [PortalCouponService] usando Dio.
class PortalCouponServiceImpl implements PortalCouponService {
  final Dio _dio;

  PortalCouponServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PortalCoupon>> getCoupons() async {
    try {
      final response = await _dio.get('/coupons');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PortalCoupon.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load coupons');
    }
  }

  @override
  Future<PortalCoupon> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/coupons', data: data);
      return PortalCoupon.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to create coupon');
    }
  }

  @override
  Future<void> deleteCoupon(String id) async {
    try {
      await _dio.delete('/coupons/$id');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete coupon');
    }
  }

  @override
  Future<void> toggleCoupon(String id, bool isActive) async {
    try {
      await _dio.patch(
        '/coupons/$id/toggle',
        data: {'is_active': isActive},
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to toggle coupon');
    }
  }
}
