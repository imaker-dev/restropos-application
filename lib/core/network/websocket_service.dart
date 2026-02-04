import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_endpoints.dart';
import '../../features/layout/data/models/layout_models.dart';
import '../../features/orders/data/models/order_models.dart';
import '../../features/tables/presentation/providers/tables_provider.dart';
import '../../features/orders/presentation/providers/orders_provider.dart';

/// WebSocket events from the server
class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String error = 'error';
  static const String tableUpdated = 'table:updated';
  static const String orderUpdated = 'order:updated';
  static const String kotUpdated = 'kot:updated';
  static const String itemReady = 'item:ready';
  static const String billGenerated = 'bill:generated';
  static const String paymentReceived = 'payment:received';
}

/// WebSocket connection state
enum SocketState { disconnected, connecting, connected, error }

/// WebSocket service for real-time updates
class WebSocketService {
  final Ref _ref;
  io.Socket? _socket;
  SocketState _state = SocketState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  final _stateController = StreamController<SocketState>.broadcast();
  Stream<SocketState> get stateStream => _stateController.stream;
  SocketState get state => _state;

  WebSocketService(this._ref);

  void connect({String? token, int? outletId}) {
    if (_socket != null && _socket!.connected) return;

    _updateState(SocketState.connecting);

    final socketUrl = ApiEndpoints.baseUrl.replaceFirst('/api/v1', '');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(3000)
          .setExtraHeaders({
            if (token != null) 'Authorization': 'Bearer $token',
          })
          .setQuery({if (outletId != null) 'outletId': outletId.toString()})
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      _updateState(SocketState.connected);
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
    });

    _socket?.onDisconnect((_) {
      _updateState(SocketState.disconnected);
      _scheduleReconnect();
    });

    _socket?.onError((error) {
      _updateState(SocketState.error);
      _scheduleReconnect();
    });

    // Table updates
    _socket?.on(SocketEvents.tableUpdated, (data) {
      try {
        final table = ApiTable.fromJson(data as Map<String, dynamic>);
        _ref.read(tablesProvider.notifier).updateTable(table);
      } catch (e) {
        // Log error
      }
    });

    // Order updates
    _socket?.on(SocketEvents.orderUpdated, (data) {
      try {
        final order = ApiOrder.fromJson(data as Map<String, dynamic>);
        _ref.read(ordersProvider.notifier).updateOrder(order);
      } catch (e) {
        // Log error
      }
    });

    // KOT updates
    _socket?.on(SocketEvents.kotUpdated, (data) {
      try {
        final kot = ApiKot.fromJson(data as Map<String, dynamic>);
        _ref.read(kotProvider.notifier).updateKot(kot);
      } catch (e) {
        // Log error
      }
    });

    // Item ready notification
    _socket?.on(SocketEvents.itemReady, (data) {
      // Trigger notification or UI update
      _handleItemReady(data);
    });
  }

  void _handleItemReady(dynamic data) {
    // Can be extended to show notifications
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  void _updateState(SocketState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void joinRoom(String room) {
    _socket?.emit('join', room);
  }

  void leaveRoom(String room) {
    _socket?.emit('leave', room);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(SocketState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }
}

// Provider for WebSocket service
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Provider for socket connection state
final socketStateProvider = StreamProvider<SocketState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.stateStream;
});

// Provider to check if socket is connected
final isSocketConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(socketStateProvider);
  return state.valueOrNull == SocketState.connected;
});
