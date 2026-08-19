/// OrdersCubit — histórico de pedidos + reorder.
///
/// Referência: ARCHITECTURE.md §Features: order_history
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/order.dart';
import '../../../domain/services/order_service.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderService _orderService;

  OrdersCubit({required OrderService orderService})
      : _orderService = orderService,
        super(const OrdersInitial());

  Future<void> loadOrders() async {
    emit(const OrdersLoading());
    final result = await _orderService.getOrders();
    result.fold(
      onSuccess: (orders) {
        if (orders.isEmpty) {
          emit(const OrdersEmpty());
        } else {
          emit(OrdersLoaded(orders: orders));
        }
      },
      onFailure: (failure) {
        emit(OrdersError(message: failure.message));
      },
    );
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrdersLoading());
    final result = await _orderService.getOrderById(orderId);
    result.fold(
      onSuccess: (order) {
        emit(OrderDetailLoaded(order: order));
      },
      onFailure: (failure) {
        emit(OrdersError(message: failure.message));
      },
    );
  }

  void clearDetail() {
    loadOrders();
  }
}
