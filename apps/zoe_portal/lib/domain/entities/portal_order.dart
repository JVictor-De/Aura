/// Entidade PortalOrder do domínio (visão lojista).
///
/// Representa um envio (shipment) de pedido no painel administrativo.
/// Cada [PortalOrder] corresponde a um [ORDER_SHIPMENTS] vinculado à loja
/// do merchant autenticado.
///
/// Referência: ARCHITECTURE.md §ERD: ORDERS, ORDER_SHIPMENTS, ORDER_ITEMS
class PortalOrder {
  /// Identificador único do envio (shipment).
  final String shipmentId;

  /// Identificador do pedido pai ao qual este envio pertence.
  final String orderId;

  /// Nome do cliente que realizou o pedido.
  final String customerName;

  /// Status atual do envio.
  ///
  /// Valores possíveis: `pending`, `confirmed`, `preparing`, `shipped`,
  /// `delivered`, `cancelled`.
  final String status;

  /// Valor total do envio (soma dos itens × quantidade).
  final double total;

  /// Quantidade total de itens neste envio.
  final int itemCount;

  /// Data/hora de criação do pedido.
  final DateTime createdAt;

  /// Lista de itens que compõem este envio.
  final List<PortalOrderItem> items;

  const PortalOrder({
    required this.shipmentId,
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.items,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalOrder.fromJson(Map<String, dynamic> json) {
    return PortalOrder(
      shipmentId: json['shipment_id'] as String,
      orderId: json['order_id'] as String,
      customerName: json['customer_name'] as String,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => PortalOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'shipment_id': shipmentId,
        'order_id': orderId,
        'customer_name': customerName,
        'status': status,
        'total': total,
        'item_count': itemCount,
        'created_at': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  /// Retorna uma cópia com o [status] atualizado.
  PortalOrder copyWithStatus(String newStatus) {
    return PortalOrder(
      shipmentId: shipmentId,
      orderId: orderId,
      customerName: customerName,
      status: newStatus,
      total: total,
      itemCount: itemCount,
      createdAt: createdAt,
      items: items,
    );
  }
}

/// Item individual dentro de um envio de pedido no portal.
///
/// Referência: ARCHITECTURE.md §ERD: ORDER_ITEMS
class PortalOrderItem {
  /// Nome do produto.
  final String productName;

  /// SKU (Stock Keeping Unit) da variante.
  final String sku;

  /// Quantidade solicitada.
  final int quantity;

  /// Preço unitário no momento da compra.
  final double unitPrice;

  const PortalOrderItem({
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalOrderItem.fromJson(Map<String, dynamic> json) {
    return PortalOrderItem(
      productName: json['product_name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'sku': sku,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}
