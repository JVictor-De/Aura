/// Entidade PaymentMethod do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: PAYMENTS
class PaymentMethod {
  final String id;
  final String type; // credit_card, debit_card, pix
  final String? lastFourDigits;
  final String? brand; // visa, mastercard, elo
  final String? holderName;
  final String? expiresAt;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.lastFourDigits,
    this.brand,
    this.holderName,
    this.expiresAt,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      lastFourDigits: json['last_four_digits'] as String?,
      brand: json['brand'] as String?,
      holderName: json['holder_name'] as String?,
      expiresAt: json['expires_at'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'last_four_digits': lastFourDigits,
        'brand': brand,
        'holder_name': holderName,
        'expires_at': expiresAt,
        'is_default': isDefault,
      };
}
