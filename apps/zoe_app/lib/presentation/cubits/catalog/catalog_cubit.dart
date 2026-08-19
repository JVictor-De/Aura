/// CatalogCubit — busca e filtro de produtos/lojas com backend.
///
/// Referência: ARCHITECTURE.md §2.7: Busca e Filtros Avançados
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/repositories/result.dart';
import '../../../domain/services/product_service.dart';
import '../../../domain/services/store_service.dart';

part 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  final ProductService _productService;
  final StoreService _storeService;

  CatalogCubit({
    required ProductService productService,
    required StoreService storeService,
  })  : _productService = productService,
        _storeService = storeService,
        super(const CatalogInitial());

  Future<void> loadHome({double? lat, double? lng}) async {
    emit(const CatalogLoading());

    Future<Result<List<Store>>> storesFuture;
    if (lat != null && lng != null) {
      storesFuture = _storeService.getNearbyStores(
        latitude: lat,
        longitude: lng,
      );
    } else {
      storesFuture = _storeService.searchStores('');
    }

    final storesResult = await storesFuture;
    final productsResult = await _productService.getProducts();

    List<Store> stores = [];
    List<Product> products = [];

    storesResult.fold(
      onSuccess: (s) => stores = s,
      onFailure: (_) {},
    );
    productsResult.fold(
      onSuccess: (p) => products = p,
      onFailure: (_) {},
    );

    emit(CatalogLoaded(stores: stores, products: products));
  }

  Future<void> searchProducts({
    String query = '',
    String? category,
    String? storeId,
    double? minPrice,
    double? maxPrice,
    String? brand,
  }) async {
    emit(const CatalogLoading());
    final result = await _productService.searchProducts(
      query: query,
      category: category,
      storeId: storeId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brand: brand,
    );
    result.fold(
      onSuccess: (products) {
        emit(CatalogSearchResults(products: products, query: query));
      },
      onFailure: (failure) {
        emit(CatalogError(message: failure.message));
      },
    );
  }

  Future<void> loadStoreProducts(String storeId) async {
    emit(const CatalogLoading());
    final result = await _productService.getProducts(storeId: storeId);
    result.fold(
      onSuccess: (products) {
        emit(CatalogStoreProducts(storeId: storeId, products: products));
      },
      onFailure: (failure) {
        emit(CatalogError(message: failure.message));
      },
    );
  }

  Future<void> loadProductDetail(String productId) async {
    emit(const CatalogLoading());
    final result = await _productService.getProductById(productId);
    result.fold(
      onSuccess: (product) {
        emit(CatalogProductDetail(product: product));
      },
      onFailure: (failure) {
        emit(CatalogError(message: failure.message));
      },
    );
  }
}
