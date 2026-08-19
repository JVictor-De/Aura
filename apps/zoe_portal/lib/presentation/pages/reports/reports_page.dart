import 'package:flutter/material.dart';

import 'package:zoe_portal/domain/entities/sales_report.dart';

/// Página de relatórios de vendas.
///
/// Exibe KPIs consolidados, vendas por dia (mini bar chart) e ranking
/// de produtos mais vendidos. Usa dados mock estáticos por enquanto.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = '30';

  // ── Mock Data ────────────────────────────────────────────────────────

  static final _mockReports = <String, SalesReport>{
    '7': const SalesReport(
      totalRevenue: 4520.00,
      totalOrders: 18,
      averageTicket: 251.11,
      totalProductsSold: 34,
      dailySales: [
        SalesByDay(date: '2026-02-22', revenue: 580.00, orders: 2),
        SalesByDay(date: '2026-02-23', revenue: 720.00, orders: 3),
        SalesByDay(date: '2026-02-24', revenue: 0, orders: 0),
        SalesByDay(date: '2026-02-25', revenue: 950.00, orders: 4),
        SalesByDay(date: '2026-02-26', revenue: 410.00, orders: 2),
        SalesByDay(date: '2026-02-27', revenue: 1120.00, orders: 5),
        SalesByDay(date: '2026-02-28', revenue: 740.00, orders: 2),
      ],
      topProducts: [
        TopProduct(productName: 'Vestido Midi Floral', quantitySold: 8, revenue: 1592.00),
        TopProduct(productName: 'Bolsa Couro Caramelo', quantitySold: 5, revenue: 995.00),
        TopProduct(productName: 'Sandália Tiras Dourada', quantitySold: 4, revenue: 716.00),
      ],
    ),
    '30': const SalesReport(
      totalRevenue: 18750.00,
      totalOrders: 72,
      averageTicket: 260.42,
      totalProductsSold: 145,
      dailySales: [
        SalesByDay(date: '2026-02-01', revenue: 620.00, orders: 3),
        SalesByDay(date: '2026-02-05', revenue: 850.00, orders: 4),
        SalesByDay(date: '2026-02-10', revenue: 1100.00, orders: 5),
        SalesByDay(date: '2026-02-15', revenue: 1450.00, orders: 6),
        SalesByDay(date: '2026-02-20', revenue: 980.00, orders: 4),
        SalesByDay(date: '2026-02-25', revenue: 1320.00, orders: 5),
        SalesByDay(date: '2026-02-28', revenue: 740.00, orders: 3),
      ],
      topProducts: [
        TopProduct(productName: 'Vestido Midi Floral', quantitySold: 32, revenue: 6368.00),
        TopProduct(productName: 'Bolsa Couro Caramelo', quantitySold: 21, revenue: 4179.00),
        TopProduct(productName: 'Sandália Tiras Dourada', quantitySold: 18, revenue: 3222.00),
        TopProduct(productName: 'Blusa Seda Off-White', quantitySold: 15, revenue: 2085.00),
        TopProduct(productName: 'Calça Wide Leg Preta', quantitySold: 12, revenue: 1788.00),
      ],
    ),
    '90': const SalesReport(
      totalRevenue: 52300.00,
      totalOrders: 198,
      averageTicket: 264.14,
      totalProductsSold: 412,
      dailySales: [
        SalesByDay(date: '2025-12-01', revenue: 1800.00, orders: 8),
        SalesByDay(date: '2025-12-15', revenue: 3200.00, orders: 14),
        SalesByDay(date: '2026-01-01', revenue: 2100.00, orders: 9),
        SalesByDay(date: '2026-01-15', revenue: 1950.00, orders: 7),
        SalesByDay(date: '2026-02-01', revenue: 2400.00, orders: 10),
        SalesByDay(date: '2026-02-15', revenue: 2850.00, orders: 11),
        SalesByDay(date: '2026-02-28', revenue: 1500.00, orders: 6),
      ],
      topProducts: [
        TopProduct(productName: 'Vestido Midi Floral', quantitySold: 85, revenue: 16915.00),
        TopProduct(productName: 'Bolsa Couro Caramelo', quantitySold: 58, revenue: 11542.00),
        TopProduct(productName: 'Sandália Tiras Dourada', quantitySold: 47, revenue: 8413.00),
        TopProduct(productName: 'Blusa Seda Off-White', quantitySold: 40, revenue: 5560.00),
        TopProduct(productName: 'Calça Wide Leg Preta', quantitySold: 35, revenue: 5215.00),
      ],
    ),
  };

  SalesReport get _currentReport => _mockReports[_selectedPeriod]!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final report = _currentReport;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text('Relatórios de Vendas', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // ── Period Selector ──
          Wrap(
            spacing: 8,
            children: [
              _PeriodChip(
                label: '7 dias',
                value: '7',
                selected: _selectedPeriod,
                onSelected: (v) => setState(() => _selectedPeriod = v),
              ),
              _PeriodChip(
                label: '30 dias',
                value: '30',
                selected: _selectedPeriod,
                onSelected: (v) => setState(() => _selectedPeriod = v),
              ),
              _PeriodChip(
                label: '90 dias',
                value: '90',
                selected: _selectedPeriod,
                onSelected: (v) => setState(() => _selectedPeriod = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── KPI Row ──
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Receita Total',
                  value: 'R\$ ${report.totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'Total de Pedidos',
                  value: report.totalOrders.toString(),
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.blue,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'Ticket Médio',
                  value: 'R\$ ${report.averageTicket.toStringAsFixed(2)}',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.orange,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'Produtos Vendidos',
                  value: report.totalProductsSold.toString(),
                  icon: Icons.inventory_2_outlined,
                  color: Colors.purple,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Charts / Lists ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendas por Dia
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vendas por Dia',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _MiniBarChart(
                              sales: report.dailySales,
                              colorScheme: colorScheme,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Top Produtos
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top Produtos',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.separated(
                              itemCount: report.topProducts.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final product = report.topProducts[index];
                                return _TopProductTile(
                                  rank: index + 1,
                                  product: product,
                                  colorScheme: colorScheme,
                                  theme: theme,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period Chip ─────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

// ─── KPI Card ────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Bar Chart ──────────────────────────────────────────────────

class _MiniBarChart extends StatelessWidget {
  final List<SalesByDay> sales;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MiniBarChart({
    required this.sales,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return Center(
        child: Text(
          'Sem dados para o período',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final maxRevenue =
        sales.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            ((constraints.maxWidth - (sales.length - 1) * 8) / sales.length)
                .clamp(20.0, 60.0);

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: sales.map((day) {
                  final heightFraction =
                      maxRevenue > 0 ? day.revenue / maxRevenue : 0.0;

                  return Tooltip(
                    message:
                        '${day.date}\nR\$ ${day.revenue.toStringAsFixed(2)}\n${day.orders} pedido(s)',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          day.orders.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: barWidth,
                          height: (constraints.maxHeight - 40) *
                              heightFraction,
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sales.map((day) {
                // Show short date label (dd/MM)
                final parts = day.date.split('-');
                final shortDate = '${parts[2]}/${parts[1]}';
                return SizedBox(
                  width: barWidth,
                  child: Text(
                    shortDate,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ─── Top Product Tile ────────────────────────────────────────────────

class _TopProductTile extends StatelessWidget {
  final int rank;
  final TopProduct product;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _TopProductTile({
    required this.rank,
    required this.product,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => Colors.amber.shade700,
      2 => Colors.grey.shade500,
      3 => Colors.brown.shade400,
      _ => colorScheme.onSurface.withValues(alpha: 0.4),
    };

    return Row(
      children: [
        // Rank badge
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${product.quantitySold} vendidos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Revenue
        Text(
          'R\$ ${product.revenue.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
