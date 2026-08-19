/// CartCubit com HydratedMixin para persistência OOM e single-store lock.
///
/// Referências:
/// - ARCHITECTURE.md §2.7: Single-Store Cart Isolation
/// - TECHNICAL_AUDIT.md §1.1: Mutex/Lock no Cubit com processamento sequencial
/// - TECHNICAL_AUDIT.md §2.2: HydratedMixin para persistência do carrinho
/// - prompt.md §Princípio 3: HydratedMixin obrigatório para CartCubit
import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:synchronized/synchronized.dart';

import '../../../domain/entities/cart_item.dart';
import 'cart_state.dart';

class CartCubit extends HydratedCubit<CartState> {
  /// Mutex para garantir execução serializada (TECHNICAL_AUDIT §1.1)
  final _mutex = Lock();

  /// Estado local dos itens (mirror do estado emitido)
  List<CartItem> _items = [];
  String? _currentStoreId;
  String? _currentStoreName;

  CartCubit() : super(CartInitial());

  // ════════════════════════════════════════════════════════════════════
  // HYDRATED BLOC — PERSISTÊNCIA OOM (TECHNICAL_AUDIT §2.2)
  // ════════════════════════════════════════════════════════════════════

  @override
  CartState? fromJson(Map<String, dynamic> json) {
    try {
      final items = (json['items'] as List? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _items = items;
      _currentStoreId = json['store_id'] as String?;
      _currentStoreName = json['store_name'] as String?;

      if (items.isEmpty) return CartInitial();

      return CartLoaded(
        items: items,
        currentStoreId: _currentStoreId,
        currentStoreName: _currentStoreName,
      );
    } catch (_) {
      return CartInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(CartState state) {
    if (state is CartLoaded) {
      return {
        'items': state.items.map((e) => e.toJson()).toList(),
        'store_id': state.currentStoreId,
        'store_name': state.currentStoreName,
      };
    }
    if (state is CartStoreConflict) {
      return {
        'items': state.currentItems.map((e) => e.toJson()).toList(),
        'store_id': state.currentStoreId,
        'store_name': state.currentStoreName,
      };
    }
    return {'items': [], 'store_id': null, 'store_name': null};
  }

  // ════════════════════════════════════════════════════════════════════
  // INTERFACE PÚBLICA
  // ════════════════════════════════════════════════════════════════════

  /// Adiciona item ao carrinho com single-store lock.
  ///
  /// Se o carrinho já tem itens de outra loja, emite [CartStoreConflict]
  /// e NÃO adiciona. O usuário deve chamar [clearAndAdd] para confirmar troca.
  Future<void> addItem(CartItem item, {String? storeName}) async {
    await _mutex.synchronized(() async {
      // Single-store check (ARCHITECTURE.md §2.7)
      if (_items.isNotEmpty &&
          _currentStoreId != null &&
          _currentStoreId != item.storeId) {
        emit(CartStoreConflict(
          currentItems: List.unmodifiable(_items),
          currentStoreId: _currentStoreId!,
          currentStoreName: _currentStoreName ?? '',
          conflictingItem: item,
          newStoreName: storeName ?? '',
        ));
        return;
      }

      // Atualizar quantidade se variante já existe
      final existingIndex =
          _items.indexWhere((i) => i.variantId == item.variantId);
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + item.quantity,
        );
      } else {
        _items = [..._items, item];
      }

      _currentStoreId = item.storeId;
      if (storeName != null) _currentStoreName = storeName;

      emit(CartLoaded(
        items: List.unmodifiable(_items),
        currentStoreId: _currentStoreId,
        currentStoreName: _currentStoreName,
        syncStatus: SyncStatus.synced,
      ));
    });
  }

  /// Limpa carrinho e adiciona item de nova loja (confirma troca de loja).
  Future<void> clearAndAdd(CartItem item, {String? storeName}) async {
    await _mutex.synchronized(() async {
      _items = [item];
      _currentStoreId = item.storeId;
      _currentStoreName = storeName;

      emit(CartLoaded(
        items: List.unmodifiable(_items),
        currentStoreId: _currentStoreId,
        currentStoreName: _currentStoreName,
        syncStatus: SyncStatus.synced,
      ));
    });
  }

  /// Atualiza quantidade de um item.
  Future<void> updateQuantity(String variantId, int newQuantity) async {
    await _mutex.synchronized(() async {
      if (newQuantity <= 0) {
        _items = _items.where((i) => i.variantId != variantId).toList();
      } else {
        final index = _items.indexWhere((i) => i.variantId == variantId);
        if (index >= 0) {
          _items[index] = _items[index].copyWith(quantity: newQuantity);
        }
      }

      if (_items.isEmpty) {
        _currentStoreId = null;
        _currentStoreName = null;
      }

      emit(CartLoaded(
        items: List.unmodifiable(_items),
        currentStoreId: _currentStoreId,
        currentStoreName: _currentStoreName,
      ));
    });
  }

  /// Remove item do carrinho.
  Future<void> removeItem(String variantId) async {
    await _mutex.synchronized(() async {
      _items = _items.where((i) => i.variantId != variantId).toList();

      if (_items.isEmpty) {
        _currentStoreId = null;
        _currentStoreName = null;
      }

      emit(CartLoaded(
        items: List.unmodifiable(_items),
        currentStoreId: _currentStoreId,
        currentStoreName: _currentStoreName,
      ));
    });
  }

  /// Limpa todo o carrinho.
  Future<void> clearCart() async {
    await _mutex.synchronized(() async {
      _items = [];
      _currentStoreId = null;
      _currentStoreName = null;
      emit(CartInitial());
    });
  }

  // ════════════════════════════════════════════════════════════════════
  // PREÇO / RESERVA CHECKS
  // ════════════════════════════════════════════════════════════════════

  /// Detecta mudanças de preço e emite CartPriceChanged.
  void handlePriceChanges(Map<String, double> serverPrices) {
    final changes = <String, PriceChange>{};

    for (final item in _items) {
      final serverPrice = serverPrices[item.variantId];
      if (serverPrice != null && serverPrice != item.unitPrice) {
        changes[item.variantId] = PriceChange(
          variantId: item.variantId,
          oldPrice: item.unitPrice,
          newPrice: serverPrice,
        );
      }
    }

    if (changes.isNotEmpty) {
      emit(CartPriceChanged(items: _items, priceChanges: changes));
    }
  }

  /// Aceita novas preços e atualiza o estado.
  void acceptPriceChanges(Map<String, double> newPrices) {
    for (var i = 0; i < _items.length; i++) {
      final newPrice = newPrices[_items[i].variantId];
      if (newPrice != null) {
        _items[i] = _items[i].copyWith(unitPrice: newPrice);
      }
    }
    emit(CartLoaded(
      items: List.unmodifiable(_items),
      currentStoreId: _currentStoreId,
      currentStoreName: _currentStoreName,
    ));
  }

  /// Getters de conveniência
  List<CartItem> get items => List.unmodifiable(_items);
  String? get currentStoreId => _currentStoreId;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
}
