/// Entidade PortalCoupon do domínio (visão lojista).
///
/// Representa um cupom de desconto gerenciado pelo merchant no painel
/// administrativo. O lojista pode criar, ativar/desativar e acompanhar
/// o uso de cada cupom.
///
/// Referência: ARCHITECTURE.md §2.2: Cupons e Promoções
/// Referência: ARCHITECTURE.md §ERD: COUPONS
class PortalCoupon {
  /// Identificador único do cupom.
  final String id;

  /// Código do cupom informado pelo cliente no checkout (ex.: "MODA10").
  final String code;

  /// Tipo de desconto: `percentage` (percentual) ou `fixed` (valor fixo).
  final String type;

  /// Valor do desconto (percentual 0–100 ou valor absoluto em reais).
  final double value;

  /// Valor mínimo do pedido para o cupom ser aplicável (opcional).
  final double? minOrderValue;

  /// Número máximo de utilizações permitidas (nulo = ilimitado).
  final int? maxUses;

  /// Quantidade de vezes que o cupom já foi utilizado.
  final int usedCount;

  /// Indica se o cupom está ativo e pode ser aplicado.
  final bool isActive;

  /// Data/hora de expiração do cupom (nulo = sem expiração).
  final DateTime? expiresAt;

  const PortalCoupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxUses,
    this.usedCount = 0,
    required this.isActive,
    this.expiresAt,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalCoupon.fromJson(Map<String, dynamic> json) {
    return PortalCoupon(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      minOrderValue: (json['min_order_value'] as num?)?.toDouble(),
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'type': type,
        'value': value,
        'min_order_value': minOrderValue,
        'max_uses': maxUses,
        'used_count': usedCount,
        'is_active': isActive,
        'expires_at': expiresAt?.toIso8601String(),
      };
}
