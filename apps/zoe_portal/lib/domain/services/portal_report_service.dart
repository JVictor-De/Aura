import 'package:zoe_portal/domain/entities/sales_report.dart';

/// Contrato do serviço de relatórios do Portal.
abstract class PortalReportService {
  /// Retorna o relatório de vendas para o [period] informado.
  ///
  /// Valores aceitos: `7d`, `30d`, `90d`.
  Future<SalesReport> getSalesReport({String? period});
}
