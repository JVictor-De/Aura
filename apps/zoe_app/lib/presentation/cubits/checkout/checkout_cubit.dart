/// CheckoutCubit — fluxo de checkout com saga simplificada.
///
/// Referência: ARCHITECTURE.md §8.3: Compensação Transacional (Checkout Seguro)
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/order.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/services/order_service.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final OrderService _orderService;

  CheckoutCubit({required OrderService orderService})
      : _orderService = orderService,
        super(const CheckoutInitial());

  void setDeliveryAddress(String addressId) {
    final current = state;
    emit(CheckoutReady(
      addressId: addressId,
      paymentMethod: current is CheckoutReady ? current.paymentMethod : null,
      couponCode: current is CheckoutReady ? current.couponCode : null,
    ));
  }

  void setPaymentMethod(String method) {
    final current = state;
    if (current is CheckoutReady) {
      emit(CheckoutReady(
        addressId: current.addressId,
        paymentMethod: method,
        couponCode: current.couponCode,
      ));
    }
  }

  void setCoupon(String? code) {
    final current = state;
    if (current is CheckoutReady) {
      emit(CheckoutReady(
        addressId: current.addressId,
        paymentMethod: current.paymentMethod,
        couponCode: code,
      ));
    }
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required String addressId,
    String? paymentMethod,
    String? couponCode,
  }) async {
    emit(const CheckoutProcessing());
    final result = await _orderService.createOrder(
      items: items,
      deliveryAddressId: addressId,
      paymentMethod: paymentMethod ?? 'pix',
      couponCode: couponCode,
    );
    result.fold(
      onSuccess: (order) {
        emit(CheckoutSuccess(order: order));
      },
      onFailure: (failure) {
        emit(CheckoutError(message: failure.message));
      },
    );
  }

  void reset() {
    emit(const CheckoutInitial());
  }
}
