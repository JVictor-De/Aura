import 'package:zoe_portal/domain/entities/portal_product.dart';

/// Contrato do serviço de inventário do Portal.
abstract class PortalInventoryService {
  /// Lista todos os produtos da loja.
  Future<List<PortalProduct>> getProducts();

  /// Retorna os detalhes de um produto específico.
  Future<PortalProduct> getProduct(String id);

  /// Cria um novo produto a partir de [data].
  Future<PortalProduct> createProduct(Map<String, dynamic> data);

  /// Atualiza um produto existente.
  Future<PortalProduct> updateProduct(String id, Map<String, dynamic> data);

  /// Remove um produto do catálogo.
  Future<void> deleteProduct(String id);

  /// Atualiza o estoque de uma variante específica.
  Future<void> updateVariantStock(String variantId, int stock);
}
