part of 'tracking_cubit.dart';

abstract class TrackingState {
  const TrackingState();
}

class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

class TrackingConnecting extends TrackingState {
  const TrackingConnecting();
}

class TrackingActive extends TrackingState {
  final DeliveryTracking tracking;
  final String orderId;

  const TrackingActive({required this.tracking, required this.orderId});
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError({required this.message});
}
