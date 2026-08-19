/// WishlistCubit — favoritos com sync backend.
///
/// Referência: ARCHITECTURE.md §2.5: Wishlist (Favoritos) e Social Proof
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../domain/entities/wishlist_item.dart';

part 'wishlist_state.dart';

class WishlistCubit extends HydratedCubit<WishlistState> {
  WishlistCubit() : super(const WishlistState(items: []));

  void toggleItem(WishlistItem item) {
    final current = List<WishlistItem>.from(state.items);
    final idx = current.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      current.removeAt(idx);
    } else {
      current.add(item);
    }
    emit(WishlistState(items: current));
  }

  void removeItem(String productId) {
    final current = state.items.where((e) => e.productId != productId).toList();
    emit(WishlistState(items: current));
  }

  bool isFavorite(String productId) {
    return state.items.any((e) => e.productId == productId);
  }

  @override
  WishlistState? fromJson(Map<String, dynamic> json) {
    try {
      final items = (json['items'] as List? ?? [])
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return WishlistState(items: items);
    } catch (_) {
      return const WishlistState(items: []);
    }
  }

  @override
  Map<String, dynamic>? toJson(WishlistState state) {
    return {
      'items': state.items.map((e) => e.toJson()).toList(),
    };
  }
}
