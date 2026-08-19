/// Entidade PortalProduct do domínio (visão lojista).
///
/// Representa um produto cadastrado na loja do merchant, incluindo suas
/// variantes de tamanho/cor (SKU). O lojista pode ativar/desativar produtos
/// e gerenciar estoque por variante.
///
/// Referência: ARCHITECTURE.md §ERD: PRODUCTS, SKU_VARIANTS
class PortalProduct {
  /// Identificador único do produto.
  final String id;

  /// Nome de exibição do produto.
  final String name;

  /// Marca / grife do produto.
  final String brand;

  /// Categoria (ex.: "Vestidos", "Calçados", "Acessórios").
  final String category;

  /// Descrição detalhada do produto (opcional).
  final String? description;

  /// Preço-base sem desconto.
  final double basePrice;

  /// Preço com desconto aplicado (nulo se não houver promoção).
  final double? discountPrice;

  /// Indica se o produto está visível no catálogo.
  final bool isActive;

  /// Lista de variantes (tamanho × cor) com estoque individual.
  final List<PortalVariant> variants;

  const PortalProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.description,
    required this.basePrice,
    this.discountPrice,
    required this.isActive,
    required this.variants,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalProduct.fromJson(Map<String, dynamic> json) {
    return PortalProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      variants: (json['variants'] as List<dynamic>?)
              ?.map(
                  (e) => PortalVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'description': description,
        'base_price': basePrice,
        'discount_price': discountPrice,
        'is_active': isActive,
        'variants': variants.map((v) => v.toJson()).toList(),
      };
}

/// Variante de SKU de um produto no portal.
///
/// Cada variante combina tamanho e cor, possuindo estoque e preço próprios.
///
/// Referência: ARCHITECTURE.md §ERD: SKU_VARIANTS
class PortalVariant {
  /// Identificador único da variante.
  final String id;

  /// Código SKU (Stock Keeping Unit).
  final String sku;

  /// Tamanho (ex.: "P", "M", "G", "42").
  final String size;

  /// Cor (ex.: "Preto", "Branco").
  final String color;

  /// Quantidade em estoque.
  final int stock;

  /// Preço unitário da variante.
  final double price;

  const PortalVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    required this.stock,
    required this.price,
  });

  /// Cria uma instância a partir de um mapa JSON retornado pela API.
  factory PortalVariant.fromJson(Map<String, dynamic> json) {
    return PortalVariant(
      id: json['id'] as String,
      sku: json['sku'] as String,
      size: json['size'] as String,
      color: json['color'] as String,
      stock: json['stock'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
    );
  }

  /// Serializa a entidade para um mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'size': size,
        'color': color,
        'stock': stock,
        'price': price,
      };
}
