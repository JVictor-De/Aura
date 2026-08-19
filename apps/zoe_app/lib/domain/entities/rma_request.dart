/// Entidade RmaRequest do domínio.
///
/// Referência: ARCHITECTURE.md §2.4: Logística Reversa Fácil (RMA)
/// ARCHITECTURE.md §ERD: RMA_REQUESTS + RMA_ITEMS
class RmaRequest {
  final String id;
  final String orderId;
  final String userId;
  final String status; // requested, approved, rejected, refunded, exchanged
  final String resolutionType; // refund, exchange
  final List<RmaItem> items;
  final DateTime requestedAt;
  final DateTime? resolvedAt;

  const RmaRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.status,
    required this.resolutionType,
    required this.items,
    required this.requestedAt,
    this.resolvedAt,
  });

  factory RmaRequest.fromJson(Map<String, dynamic> json) {
    return RmaRequest(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      resolutionType: json['resolution_type'] as String? ?? 'refund',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RmaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requestedAt: DateTime.parse(json['requested_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'user_id': userId,
        'status': status,
        'resolution_type': resolutionType,
        'items': items.map((e) => e.toJson()).toList(),
        'requested_at': requestedAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}

class RmaItem {
  final String id;
  final String orderItemId;
  final int quantity;
  final String reason; // wrong_size, defect, changed_mind, wrong_item
  final String condition; // unopened, used, damaged

  const RmaItem({
    required this.id,
    required this.orderItemId,
    required this.quantity,
    required this.reason,
    required this.condition,
  });

  factory RmaItem.fromJson(Map<String, dynamic> json) {
    return RmaItem(
      id: json['id'] as String,
      orderItemId: json['order_item_id'] as String,
      quantity: json['quantity'] as int,
      reason: json['reason'] as String,
      condition: json['condition'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_item_id': orderItemId,
        'quantity': quantity,
        'reason': reason,
        'condition': condition,
      };
}
