part of 'catalog_cubit.dart';

abstract class CatalogState {
  const CatalogState();
}

class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

class CatalogLoaded extends CatalogState {
  final List<Store> stores;
  final List<Product> products;

  const CatalogLoaded({required this.stores, required this.products});
}

class CatalogSearchResults extends CatalogState {
  final List<Product> products;
  final String query;

  const CatalogSearchResults({required this.products, required this.query});
}

class CatalogStoreProducts extends CatalogState {
  final String storeId;
  final List<Product> products;

  const CatalogStoreProducts({required this.storeId, required this.products});
}

class CatalogProductDetail extends CatalogState {
  final Product product;

  const CatalogProductDetail({required this.product});
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError({required this.message});
}
