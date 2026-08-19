/// Painel de pedidos em tempo real via WebSocket.
///
/// Referências:
/// - prompt.md §3: painel de pedidos em tempo real que consome WebSockets
///   e exibe somente os splits confirmados da loja autenticada
/// - ARCHITECTURE.md §WebSocket para Real-time Updates: subscribeToOrder
/// - ARCHITECTURE.md §Fluxo do Lojista: Pedidos Recebidos → Aceitar/Rejeitar
/// - TECHNICAL_AUDIT.md §1.4: WebSocket com fallback para polling HTTP (30s)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  WebSocketChannel? _channel;
  final List<_OrderShipment> _shipments = [];
  Timer? _pollingTimer;
  bool _wsConnected = false;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  /// Conecta ao WebSocket do backend (ARCHITECTURE.md §WebSocket)
  void _connectWebSocket() {
    try {
      // Em produção: usar token JWT real e URL do EnvConfig
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8000/api/v1/ws/orders?token=JWT_TOKEN'),
      );

      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          _wsConnected = true;
          _pollingTimer?.cancel(); // Cancelar polling se WS conectou

          final msg = jsonDecode(data);
          _handleMessage(msg);
        },
        onError: (_) => _handleWsError(),
        onDone: () => _handleWsError(),
      );
    } catch (_) {
      _handleWsError();
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    setState(() {
      if (msg['type'] == 'INITIAL_SHIPMENTS') {
        _shipments.clear();
        for (final s in msg['payload']) {
          _shipments.add(_OrderShipment(
            shipmentId: s['shipment_id'],
            orderId: s['order_id'],
            status: s['status'],
          ));
        }
      } else if (msg['type'] == 'ORDER_STATUS') {
        final payload = msg['payload'];
        final index = _shipments.indexWhere((s) => s.shipmentId == payload['shipment_id']);
        if (index >= 0) {
          _shipments[index] = _shipments[index].copyWith(status: payload['status']);
        } else {
          _shipments.insert(0, _OrderShipment(
            shipmentId: payload['shipment_id'],
            orderId: payload['order_id'],
            status: payload['status'],
          ));
        }
      }
    });
  }

  /// Fallback para polling HTTP quando WebSocket falha
  /// (TECHNICAL_AUDIT.md §1.4: polling a cada 30s)
  void _handleWsError() {
    _wsConnected = false;
    _reconnectAttempts++;

    if (_reconnectAttempts <= _maxReconnectAttempts) {
      final delay = Duration(seconds: 1 << _reconnectAttempts); // exponential backoff
      Future.delayed(delay, _connectWebSocket);
    } else {
      // Fallback: polling HTTP a cada 30s (TECHNICAL_AUDIT §1.4)
      _startPollingFallback();
    }
  }

  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Em produção: GET /orders filtrado por store_id
      // Aqui simulamos manter os dados atuais
    });

    // Tentar reconectar WS em 2 minutos
    Future.delayed(const Duration(minutes: 2), () {
      _reconnectAttempts = 0;
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Pedidos', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(width: 12),
              // Indicador de conexão WebSocket
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _wsConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _wsConnected ? Icons.wifi : Icons.wifi_off,
                      size: 14,
                      color: _wsConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _wsConnected ? 'Tempo Real' : 'Polling',
                      style: TextStyle(
                        fontSize: 12,
                        color: _wsConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de pedidos (splits confirmados da loja)
          Expanded(
            child: _shipments.isEmpty
                ? const Center(child: Text('Nenhum pedido recebido'))
                : Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _shipments.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final s = _shipments[index];
                        return _OrderShipmentTile(
                          shipment: s,
                          onAccept: () => _updateStatus(s.shipmentId, 'confirmed'),
                          onReject: () => _updateStatus(s.shipmentId, 'cancelled'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String shipmentId, String newStatus) {
    // Enviar via WebSocket
    _channel?.sink.add(jsonEncode({
      'action': 'UPDATE_STATUS',
      'shipment_id': shipmentId,
      'status': newStatus,
    }));

    setState(() {
      final index = _shipments.indexWhere((s) => s.shipmentId == shipmentId);
      if (index >= 0) {
        _shipments[index] = _shipments[index].copyWith(status: newStatus);
      }
    });
  }
}

class _OrderShipmentTile extends StatelessWidget {
  final _OrderShipment shipment;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OrderShipmentTile({
    required this.shipment,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _StatusIcon(status: shipment.status),
      title: Text('Pedido #${shipment.orderId.substring(0, 8)}'),
      subtitle: Text('Shipment: ${shipment.shipmentId.substring(0, 8)} · ${shipment.status.toUpperCase()}'),
      trailing: shipment.status == 'pending'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: onAccept,
                  tooltip: 'Aceitar',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: onReject,
                  tooltip: 'Rejeitar',
                ),
              ],
            )
          : null,
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'pending' => (Icons.schedule, Colors.orange),
      'confirmed' => (Icons.check_circle, Colors.green),
      'preparing' => (Icons.restaurant, Colors.blue),
      'shipped' => (Icons.local_shipping, Colors.purple),
      'delivered' => (Icons.done_all, Colors.green),
      'cancelled' => (Icons.cancel, Colors.red),
      _ => (Icons.help, Colors.grey),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _OrderShipment {
  final String shipmentId;
  final String orderId;
  final String status;

  const _OrderShipment({
    required this.shipmentId,
    required this.orderId,
    required this.status,
  });

  _OrderShipment copyWith({String? status}) {
    return _OrderShipment(
      shipmentId: shipmentId,
      orderId: orderId,
      status: status ?? this.status,
    );
  }
}
