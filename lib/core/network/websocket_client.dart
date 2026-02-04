import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketClient {
  io.Socket? _socket;
  final Logger _logger = Logger();
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<WebSocketEvent> get events => _eventController.stream;
  ConnectionStatus get status => _status;

  void connect({String? token}) {
    if (_socket != null && _socket!.connected) {
      _logger.d('WebSocket already connected');
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _logger.i('WebSocket connected');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);
    });

    _socket?.onDisconnect((_) {
      _logger.w('WebSocket disconnected');
      _updateStatus(ConnectionStatus.disconnected);
    });

    _socket?.onConnectError((error) {
      _logger.e('WebSocket connection error: $error');
      _updateStatus(ConnectionStatus.error);
      _attemptReconnect();
    });

    _socket?.onError((error) {
      _logger.e('WebSocket error: $error');
      _updateStatus(ConnectionStatus.error);
    });

    // POS-specific events
    _registerPosEvents();
  }

  void _registerPosEvents() {
    final events = [
      'TABLE_STATUS_UPDATED',
      'ORDER_UPDATED',
      'ITEM_ADDED',
      'ITEM_REMOVED',
      'KOT_CREATED',
      'KOT_PRINTED',
      'KOT_CANCELLED',
      'BILL_GENERATED',
      'PAYMENT_SUCCESS',
      'TABLE_CLOSED',
      'TABLE_TRANSFERRED',
      'TABLE_MERGED',
      'TABLE_SPLIT',
      'MENU_UPDATED',
      'PRICE_UPDATED',
    ];

    for (final event in events) {
      _socket?.on(event, (data) {
        _logger.d('Received event: $event, data: $data');
        _eventController.add(WebSocketEvent(event: event, data: data));
      });
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      return;
    }

    _updateStatus(ConnectionStatus.reconnecting);
    _reconnectAttempts++;

    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _logger.i('Attempting reconnection (${_reconnectAttempts}/$maxReconnectAttempts)');
      _socket?.connect();
    });
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
  }

  void emit(String event, dynamic data) {
    if (_socket?.connected ?? false) {
      _socket?.emit(event, data);
      _logger.d('Emitted event: $event, data: $data');
    } else {
      _logger.w('Cannot emit event: WebSocket not connected');
    }
  }

  void subscribe(String channel, {Map<String, dynamic>? params}) {
    emit('subscribe', {'channel': channel, ...?params});
  }

  void unsubscribe(String channel) {
    emit('unsubscribe', {'channel': channel});
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _eventController.close();
  }
}

class WebSocketEvent {
  final String event;
  final dynamic data;

  WebSocketEvent({required this.event, required this.data});
}
