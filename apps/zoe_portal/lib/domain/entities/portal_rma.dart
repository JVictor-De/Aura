/// Entidade PortalRma do domínio (visão lojista).
///
/// Representa uma solicitação de devolução/troca (RMA — Return Merchandise
/// Authorization) recebida pelo merchant. O lojista pode aprovar, rejeitar
/// ou concluir a devolução com estorno parcial via [PaymentService].
///
/// Referência: ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
/// Referência: ARCHITECTURE.md §ERD: RMA_REQUESTS, RMA_ITEMS
class PortalRma {
  /// Identificador único da solicitação de RMA.
  final String id;

  /// Identificador do pedido original.
  final String orderId;

  /// Nome do cliente solicitante.
  final String customerName;

  /// Motivo informado pelo cliente para a devolução.
  final String reason;

  /// Status atual da solicitação: `requested`, `approved`, `rejected`,
  /// `completed`.
  final String status;

  /// Valor do estorno a ser processado.
  final double refundAmount;

  /// Data/hora em que a solicitação foi criada.
  final DateTime createdAt;

  /// Itens incluídos na solicitação de devolução.
  final List<PortalRmaItem> items;

  const PortalRma({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.reason,
    required this.status,
    required this.refundAmount,
    required this.createdAt,
    required this.items,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalRma.fromJson(Map<String, dynamic> json) {
    return PortalRma(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerName: json['customer_name'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      refundAmount: (json['refund_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => PortalRmaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'customer_name': customerName,
        'reason': reason,
        'status': status,
        'refund_amount': refundAmount,
        'created_at': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Item individual dentro de uma solicitação de RMA.
///
/// Referência: ARCHITECTURE.md §ERD: RMA_ITEMS
class PortalRmaItem {
  /// Nome do produto devolvido.
  final String productName;

  /// SKU (Stock Keeping Unit) da variante devolvida.
  final String sku;

  /// Quantidade devolvida.
  final int quantity;

  const PortalRmaItem({
    required this.productName,
    required this.sku,
    required this.quantity,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalRmaItem.fromJson(Map<String, dynamic> json) {
    return PortalRmaItem(
      productName: json['product_name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'sku': sku,
        'quantity': quantity,
      };
}
