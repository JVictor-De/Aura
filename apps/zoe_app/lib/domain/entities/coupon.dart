/// Entidade Coupon do domínio.
///
/// Referência: ARCHITECTURE.md §2.2: Cupons e Promoções
class Coupon {
  final String id;
  final String code;
  final String discountType; // FIXED, PERCENTAGE
  final double discountValue;
  final double? minPurchase;
  final bool isActive;
  final DateTime? validUntil;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minPurchase,
    required this.isActive,
    this.validUntil,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: json['id'] as String,
        code: json['code'] as String,
        discountType: json['discount_type'] as String,
        discountValue: (json['discount_value'] as num).toDouble(),
        minPurchase: (json['min_purchase'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool,
        validUntil: json['valid_until'] != null
            ? DateTime.parse(json['valid_until'] as String)
            : null,
      );
}
