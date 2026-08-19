/// CartState: estados imutáveis do carrinho single-store.
///
/// Referências:
/// - ARCHITECTURE.md §2.7: Single-Store Cart Isolation
/// - ARCHITECTURE.md §Estrutura de Estado no Flutter (Cubit):
///   - CartStockExpired: reserva expirou → revalidar
///   - CartPriceChanged: preço atualizado → mostrar diff
///   - CartReservationExpiring: aviso 2 min antes de expirar
///   - CartStoreConflict: item de outra loja → confirmar troca
/// - TECHNICAL_AUDIT.md §1.1: estados imutáveis com BlocConcurrency
import 'package:equatable/equatable.dart';

import '../../../domain/entities/cart_item.dart';

/// Status de sincronização com o servidor
enum SyncStatus { synced, syncing, error, offline }

/// Estado base do carrinho (ARCHITECTURE.md §Estrutura de Estado)
abstract class CartState extends Equatable {
  const CartState();
}

/// Estado inicial (carrinho vazio)
class CartInitial extends CartState {
  @override
  List<Object?> get props => [];
}

/// Carregando carrinho
class CartLoading extends CartState {
  @override
  List<Object?> get props => [];
}

/// Carrinho carregado com itens (single-store)
class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? currentStoreId;
  final String? currentStoreName;
  final SyncStatus syncStatus;

  const CartLoaded({
    required this.items,
    this.currentStoreId,
    this.currentStoreName,
    this.syncStatus = SyncStatus.synced,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, currentStoreId, syncStatus];
}

/// Conflito de loja: item de outra loja adicionado
/// (ARCHITECTURE.md §2.7: Single-Store Cart Isolation)
class CartStoreConflict extends CartState {
  final List<CartItem> currentItems;
  final String currentStoreId;
  final String currentStoreName;
  final CartItem conflictingItem;
  final String newStoreName;

  const CartStoreConflict({
    required this.currentItems,
    required this.currentStoreId,
    required this.currentStoreName,
    required this.conflictingItem,
    required this.newStoreName,
  });

  @override
  List<Object?> get props => [currentStoreId, conflictingItem.variantId];
}

/// Reserva de estoque expirou (ARCHITECTURE.md §CartStockExpired)
class CartStockExpired extends CartState {
  final List<CartItem> items;
  final List<String> expiredVariantIds;

  const CartStockExpired({required this.items, required this.expiredVariantIds});

  @override
  List<Object?> get props => [items, expiredVariantIds];
}

/// Preço alterado durante a sessão (ARCHITECTURE.md §CartPriceChanged)
class CartPriceChanged extends CartState {
  final List<CartItem> items;
  final Map<String, PriceChange> priceChanges;

  const CartPriceChanged({required this.items, required this.priceChanges});

  @override
  List<Object?> get props => [items, priceChanges];
}

class PriceChange extends Equatable {
  final String variantId;
  final double oldPrice;
  final double newPrice;

  const PriceChange({
    required this.variantId,
    required this.oldPrice,
    required this.newPrice,
  });

  @override
  List<Object?> get props => [variantId, oldPrice, newPrice];
}

/// Aviso de expiração em 2 minutos (ARCHITECTURE.md §CartReservationExpiring)
class CartReservationExpiring extends CartState {
  final List<CartItem> items;
  final DateTime expiresAt;

  const CartReservationExpiring({required this.items, required this.expiresAt});

  @override
  List<Object?> get props => [items, expiresAt];
}

/// Erro no carrinho
class CartError extends CartState {
  final String message;
  final List<CartItem> previousItems;

  const CartError({required this.message, this.previousItems = const []});

  @override
  List<Object?> get props => [message, previousItems];
}
