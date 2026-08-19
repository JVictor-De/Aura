import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_order.dart';
import 'package:zoe_portal/domain/services/portal_order_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalOrdersState extends Equatable {
  const PortalOrdersState();

  @override
  List<Object?> get props => [];
}

class PortalOrdersInitial extends PortalOrdersState {
  const PortalOrdersInitial();
}

class PortalOrdersLoading extends PortalOrdersState {
  const PortalOrdersLoading();
}

class PortalOrdersLoaded extends PortalOrdersState {
  final List<PortalOrder> orders;

  const PortalOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class PortalOrdersError extends PortalOrdersState {
  final String message;

  const PortalOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalOrdersCubit extends Cubit<PortalOrdersState> {
  final PortalOrderService _orderService;

  PortalOrdersCubit({required PortalOrderService orderService})
      : _orderService = orderService,
        super(const PortalOrdersInitial());

  /// Carrega a lista de pedidos com filtro opcional por [status].
  Future<void> loadOrders({String? status}) async {
    emit(const PortalOrdersLoading());
    try {
      final orders = await _orderService.getOrders(status: status);
      emit(PortalOrdersLoaded(orders));
    } catch (e) {
      emit(PortalOrdersError(e.toString()));
    }
  }

  /// Atualiza o status de um envio e recarrega a lista.
  Future<void> updateStatus(String shipmentId, String status) async {
    try {
      await _orderService.updateOrderStatus(shipmentId, status);
      // Reload orders preserving current filter
      await loadOrders();
    } catch (e) {
      emit(PortalOrdersError(e.toString()));
    }
  }
}
