/// Entidade DeliveryTracking do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: DELIVERY_TRACKING
class DeliveryTracking {
  final String id;
  final String orderId;
  final String? driverName;
  final String? driverPhone;
  final double? currentLat;
  final double? currentLng;
  final String status; // assigned, picking_up, en_route, arriving, delivered
  final DateTime? estimatedArrival;
  final DateTime? updatedAt;

  const DeliveryTracking({
    required this.id,
    required this.orderId,
    this.driverName,
    this.driverPhone,
    this.currentLat,
    this.currentLng,
    required this.status,
    this.estimatedArrival,
    this.updatedAt,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    return DeliveryTracking(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      status: json['status'] as String,
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.parse(json['estimated_arrival'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'current_lat': currentLat,
        'current_lng': currentLng,
        'status': status,
        'estimated_arrival': estimatedArrival?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
