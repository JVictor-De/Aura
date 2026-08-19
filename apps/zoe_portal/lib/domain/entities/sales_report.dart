/// Entidade SalesReport do domínio (visão lojista).
///
/// Relatório consolidado de vendas da loja, incluindo receita total,
/// ticket médio, vendas diárias e produtos mais vendidos.
/// Utilizado no dashboard principal do Zoe Portal.
///
/// Referência: ARCHITECTURE.md §1: Zoe Portal — Dashboard Administrativo
class SalesReport {
  /// Receita total no período selecionado.
  final double totalRevenue;

  /// Número total de pedidos no período.
  final int totalOrders;

  /// Ticket médio (receita ÷ pedidos).
  final double averageTicket;

  /// Quantidade total de produtos vendidos (soma de itens).
  final int totalProductsSold;

  /// Detalhamento de vendas por dia dentro do período.
  final List<SalesByDay> dailySales;

  /// Ranking dos produtos mais vendidos no período.
  final List<TopProduct> topProducts;

  const SalesReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageTicket,
    required this.totalProductsSold,
    required this.dailySales,
    required this.topProducts,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalOrders: json['total_orders'] as int,
      averageTicket: (json['average_ticket'] as num).toDouble(),
      totalProductsSold: json['total_products_sold'] as int? ?? 0,
      dailySales: (json['daily_sales'] as List<dynamic>?)
              ?.map((e) => SalesByDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts: (json['top_products'] as List<dynamic>?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Vendas consolidadas de um único dia.
class SalesByDay {
  /// Data no formato ISO 8601 (ex.: "2026-02-28").
  final String date;

  /// Receita do dia.
  final double revenue;

  /// Número de pedidos do dia.
  final int orders;

  const SalesByDay({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory SalesByDay.fromJson(Map<String, dynamic> json) {
    return SalesByDay(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      orders: json['orders'] as int,
    );
  }
}

/// Produto mais vendido no período do relatório.
class TopProduct {
  /// Nome do produto.
  final String productName;

  /// Quantidade total vendida.
  final int quantitySold;

  /// Receita gerada por este produto.
  final double revenue;

  const TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['product_name'] as String,
      quantitySold: json['quantity_sold'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
