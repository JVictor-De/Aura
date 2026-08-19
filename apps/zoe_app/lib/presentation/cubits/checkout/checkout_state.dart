part of 'checkout_cubit.dart';

abstract class CheckoutState {
  const CheckoutState();
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutReady extends CheckoutState {
  final String addressId;
  final String? paymentMethod;
  final String? couponCode;

  const CheckoutReady({
    required this.addressId,
    this.paymentMethod,
    this.couponCode,
  });
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing();
}

class CheckoutSuccess extends CheckoutState {
  final Order order;
  const CheckoutSuccess({required this.order});
}

class CheckoutError extends CheckoutState {
  final String message;
  const CheckoutError({required this.message});
}
