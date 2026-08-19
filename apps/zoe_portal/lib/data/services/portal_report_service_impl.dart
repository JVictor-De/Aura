import 'package:dio/dio.dart';

import 'package:zoe_portal/domain/entities/sales_report.dart';
import 'package:zoe_portal/domain/services/portal_report_service.dart';

/// Implementação de [PortalReportService] usando Dio.
class PortalReportServiceImpl implements PortalReportService {
  final Dio _dio;

  PortalReportServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<SalesReport> getSalesReport({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;

      final response = await _dio.get(
        '/reports/sales',
        queryParameters: queryParams,
      );

      return SalesReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load sales report');
    }
  }
}
