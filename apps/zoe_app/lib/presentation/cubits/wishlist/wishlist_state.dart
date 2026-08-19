part of 'wishlist_cubit.dart';

class WishlistState {
  final List<WishlistItem> items;

  const WishlistState({required this.items});

  int get count => items.length;
}
