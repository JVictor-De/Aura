import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_product.dart';
import 'package:zoe_portal/domain/services/portal_inventory_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalInventoryState extends Equatable {
  const PortalInventoryState();

  @override
  List<Object?> get props => [];
}

class PortalInventoryInitial extends PortalInventoryState {
  const PortalInventoryInitial();
}

class PortalInventoryLoading extends PortalInventoryState {
  const PortalInventoryLoading();
}

class PortalInventoryLoaded extends PortalInventoryState {
  final List<PortalProduct> products;

  const PortalInventoryLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class PortalInventoryError extends PortalInventoryState {
  final String message;

  const PortalInventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalInventoryCubit extends Cubit<PortalInventoryState> {
  final PortalInventoryService _inventoryService;

  PortalInventoryCubit({required PortalInventoryService inventoryService})
      : _inventoryService = inventoryService,
        super(const PortalInventoryInitial());

  /// Carrega todos os produtos da loja.
  Future<void> loadProducts() async {
    emit(const PortalInventoryLoading());
    try {
      final products = await _inventoryService.getProducts();
      emit(PortalInventoryLoaded(products));
    } catch (e) {
      emit(PortalInventoryError(e.toString()));
    }
  }

  /// Cria um novo produto e recarrega a lista.
  Future<void> createProduct(Map<String, dynamic> data) async {
    emit(const PortalInventoryLoading());
    try {
      await _inventoryService.createProduct(data);
      await loadProducts();
    } catch (e) {
      emit(PortalInventoryError(e.toString()));
    }
  }

  /// Atualiza um produto existente e recarrega a lista.
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    emit(const PortalInventoryLoading());
    try {
      await _inventoryService.updateProduct(id, data);
      await loadProducts();
    } catch (e) {
      emit(PortalInventoryError(e.toString()));
    }
  }

  /// Remove um produto e recarrega a lista.
  Future<void> deleteProduct(String id) async {
    emit(const PortalInventoryLoading());
    try {
      await _inventoryService.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      emit(PortalInventoryError(e.toString()));
    }
  }

  /// Atualiza o estoque de uma variante e recarrega a lista.
  Future<void> updateStock(String variantId, int stock) async {
    try {
      await _inventoryService.updateVariantStock(variantId, stock);
      await loadProducts();
    } catch (e) {
      emit(PortalInventoryError(e.toString()));
    }
  }
}
