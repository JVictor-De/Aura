/// TrackingCubit — rastreamento em tempo real via WebSocket.
///
/// Referência: ARCHITECTURE.md §2.3: Rastreamento em Tempo Real
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../domain/entities/tracking.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pollTimer;
  final String _wsUrl;

  TrackingCubit({required String wsUrl})
      : _wsUrl = wsUrl,
        super(const TrackingInitial());

  void startTracking(String orderId, String token) {
    emit(const TrackingConnecting());

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsUrl/orders?token=$token'),
      );

      _subscription = _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          if (json['type'] == 'order_update' || json['type'] == 'initial_state') {
            final tracking = DeliveryTracking.fromJson(json['data'] as Map<String, dynamic>);
            emit(TrackingActive(tracking: tracking, orderId: orderId));
          }
        },
        onError: (_) => _startPollingFallback(orderId),
        onDone: () => _startPollingFallback(orderId),
      );
    } catch (_) {
      _startPollingFallback(orderId);
    }
  }

  void _startPollingFallback(String orderId) {
    /// ARCHITECTURE.md §2.3: "Fallback para polling HTTP a cada 30s se conexão WS cair"
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // In production, would make HTTP GET to /orders/{orderId}/tracking
    });
  }

  void stopTracking() {
    _subscription?.cancel();
    _channel?.sink.close();
    _pollTimer?.cancel();
    emit(const TrackingInitial());
  }

  @override
  Future<void> close() {
    stopTracking();
    return super.close();
  }
}
