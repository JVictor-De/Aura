/// Contrato do CartService (Facade pattern).
///
/// Referências:
/// - ARCHITECTURE.md §2.7: Single-Store Cart Isolation
/// - TECHNICAL_AUDIT.md §F-2: Store Conflict — carrinho vazio antes de trocar loja
import '../entities/cart_item.dart';
import '../repositories/result.dart';

abstract class CartService {
  /// Adiciona item ao carrinho. Retorna erro StoreConflict se loja difere.
  Future<Result<void>> addToCart(CartItem item);

  /// Remove item do carrinho.
  Future<Result<void>> removeFromCart(String variantId);

  /// Atualiza quantidade de item.
  Future<Result<void>> updateQuantity(String variantId, int quantity);

  /// Limpa carrinho (necessário antes de trocar de loja).
  Future<Result<void>> clearCart();

  /// Limpa carrinho e adiciona novo item (fluxo de troca de loja confirmada).
  Future<Result<void>> clearAndAdd(CartItem item);

  /// Valida preços do carrinho com o backend.
  Future<Result<List<CartItem>>> validatePrices();
}
