/// Contrato do ProductService (Facade pattern).
///
/// Referências:
/// - ARCHITECTURE.md §Pragmatic Clean Architecture: Service/Facade
import '../entities/product.dart';
import '../repositories/result.dart';

abstract class ProductService {
  Future<Result<List<Product>>> getProducts({
    String? storeId,
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<Result<Product>> getProductById(String id);

  Future<Result<List<Product>>> searchProducts({
    String query = '',
    String? category,
    String? storeId,
    double? minPrice,
    double? maxPrice,
    String? brand,
  });
}
