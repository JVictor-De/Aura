/// Contrato do WishlistService.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist (Favoritos)
import '../entities/wishlist_item.dart';
import '../repositories/result.dart';

abstract class WishlistService {
  Future<Result<List<WishlistItem>>> getWishlist();
  Future<Result<void>> addToWishlist(String productId);
  Future<Result<void>> removeFromWishlist(String productId);
}
