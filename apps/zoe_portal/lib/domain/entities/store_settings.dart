/// Entidade StoreSettings do domínio (visão lojista).
///
/// Representa as configurações da loja do merchant, incluindo informações
/// de entrega, identidade visual e regras de pedido mínimo.
///
/// Referência: ARCHITECTURE.md §ERD: STORES
class StoreSettings {
  /// Identificador único da loja.
  final String storeId;

  /// Nome de exibição da loja.
  final String storeName;

  /// Descrição da loja exibida no catálogo (opcional).
  final String? description;

  /// URL do logotipo da loja hospedado na CDN (opcional).
  ///
  /// Referência: ARCHITECTURE.md §3.2: Validação do Fluxo de Dados e Imagens
  final String? logoUrl;

  /// Indica se a loja está ativa e visível para os clientes.
  final bool isActive;

  /// Taxa de entrega padrão cobrada por pedido.
  final double deliveryFee;

  /// Tempo estimado de entrega exibido ao cliente (ex.: "40-60 min").
  final String estimatedDeliveryTime;

  /// Valor mínimo do pedido para aceitar uma compra (opcional).
  final double? minOrderValue;

  const StoreSettings({
    required this.storeId,
    required this.storeName,
    this.description,
    this.logoUrl,
    required this.isActive,
    required this.deliveryFee,
    required this.estimatedDeliveryTime,
    this.minOrderValue,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeId: json['store_id'] as String? ?? json['id'] as String,
      storeName: json['store_name'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      estimatedDeliveryTime:
          json['estimated_delivery_time'] as String? ?? '',
      minOrderValue: (json['min_order_value'] as num?)?.toDouble(),
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'store_id': storeId,
        'store_name': storeName,
        'description': description,
        'logo_url': logoUrl,
        'is_active': isActive,
        'delivery_fee': deliveryFee,
        'estimated_delivery_time': estimatedDeliveryTime,
        'min_order_value': minOrderValue,
      };
}
