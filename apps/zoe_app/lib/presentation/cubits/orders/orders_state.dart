part of 'orders_cubit.dart';

abstract class OrdersState {
  const OrdersState();
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersEmpty extends OrdersState {
  const OrdersEmpty();
}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded({required this.orders});
}

class OrderDetailLoaded extends OrdersState {
  final Order order;
  const OrderDetailLoaded({required this.order});
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError({required this.message});
}
