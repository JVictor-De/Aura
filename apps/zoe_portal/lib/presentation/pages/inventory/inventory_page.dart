/// Gestão de inventário do lojista.
///
/// Referências:
/// - prompt.md §3: gestão de inventário crítico, cadastro de SKUs
///   e controle de estoque por variação
/// - ARCHITECTURE.md §Fluxo do Lojista: Inventário → Adicionar Produtos
/// - ARCHITECTURE.md §ERD: PRODUCTS, SKU_VARIANTS
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Dados mock (em produção: vem do InventoryCubit via API /inventory/products)
  final _products = [
    _MockProduct(
      name: 'Vestido Midi Seda',
      brand: 'Zoe Atelier',
      category: 'Dresses',
      variants: [
        _MockVariant(sku: 'DRESS-BLK-P', size: 'P', color: 'Preto', stock: 5, price: 899.90),
        _MockVariant(sku: 'DRESS-BLK-M', size: 'M', color: 'Preto', stock: 3, price: 899.90),
        _MockVariant(sku: 'DRESS-BLK-G', size: 'G', color: 'Preto', stock: 0, price: 899.90),
      ],
    ),
    _MockProduct(
      name: 'Blazer Linho',
      brand: 'Zoe Atelier',
      category: 'Outerwear',
      variants: [
        _MockVariant(sku: 'BLZR-BGE-M', size: 'M', color: 'Bege', stock: 8, price: 1299.90),
        _MockVariant(sku: 'BLZR-BGE-G', size: 'G', color: 'Bege', stock: 2, price: 1299.90),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventário', style: Theme.of(context).textTheme.headlineMedium),
              FilledButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('NOVO PRODUTO'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabela de produtos com variações
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _ProductInventoryTile(product: product);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Produto'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Nome do Produto')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Marca')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Categoria')),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Preço Base (R\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text('Variações (SKUs)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              // Em produção: formulário dinâmico de variações
              const Text(
                'Após criar o produto, adicione variações (cor/tamanho) na tela de detalhe.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CRIAR')),
        ],
      ),
    );
  }
}

/// Tile expandível mostrando produto e suas variações SKU
class _ProductInventoryTile extends StatelessWidget {
  final _MockProduct product;

  const _ProductInventoryTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${product.brand} · ${product.category}'),
      trailing: _StockBadge(
        total: product.variants.fold(0, (sum, v) => sum + v.stock),
      ),
      children: [
        // Cabeçalho da tabela de variações
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Tamanho', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Cor', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Estoque', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Preço', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              ...product.variants.map((v) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(v.sku, style: const TextStyle(fontFamily: 'monospace'))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(v.size)),
                  Padding(padding: const EdgeInsets.all(8), child: Text(v.color)),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _StockBadge(total: v.stock),
                  ),
                  Padding(padding: const EdgeInsets.all(8), child: Text('R\$ ${v.price.toStringAsFixed(2)}')),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int total;
  const _StockBadge({required this.total});

  @override
  Widget build(BuildContext context) {
    final color = total == 0
        ? Colors.red
        : total <= 3
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$total un.',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

// Mock data classes (em produção: entities do domínio)
class _MockProduct {
  final String name;
  final String brand;
  final String category;
  final List<_MockVariant> variants;
  const _MockProduct({required this.name, required this.brand, required this.category, required this.variants});
}

class _MockVariant {
  final String sku;
  final String size;
  final String color;
  final int stock;
  final double price;
  const _MockVariant({required this.sku, required this.size, required this.color, required this.stock, required this.price});
}
