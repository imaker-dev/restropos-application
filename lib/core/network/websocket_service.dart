import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_endpoints.dart';

/// WebSocket events from the server
class SocketEvents {
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String error = 'error';
  static const String tableUpdated = 'table:updated';
  static const String orderUpdated = 'order:updated';
  static const String kotUpdated = 'kot:updated';
  static const String kotItemCancelled = 'kot:item_cancelled';
  static const String itemReady = 'item:ready';
  static const String billStatus = 'bill:status';
  static const String billGenerated = 'bill:generated';
  static const String paymentReceived = 'payment:received';
}

/// WebSocket connection state
enum SocketState { disconnected, connecting, connected, error }

/// WebSocket service for real-time updates
/// Implements architecture from Real-Time Integration Guide
class WebSocketService {
  io.Socket? _socket;
  SocketState _state = SocketState.disconnected;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Track current outlet and floor for room joining
  int? _currentOutletId;
  int? _currentFloorId;
  String? _currentToken;

  // Stream controllers for different events (broadcast to multiple listeners)
  final _stateController = StreamController<SocketState>.broadcast();
  final _tableUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _billStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _itemReadyController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _kotUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _kotItemCancelledController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<SocketState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get tableUpdates =>
      _tableUpdateController.stream;
  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdateController.stream;
  Stream<Map<String, dynamic>> get billStatus => _billStatusController.stream;
  Stream<Map<String, dynamic>> get itemReady => _itemReadyController.stream;
  Stream<Map<String, dynamic>> get kotUpdates => _kotUpdateController.stream;
  Stream<Map<String, dynamic>> get kotItemCancelled =>
      _kotItemCancelledController.stream;

  SocketState get state => _state;
  bool get isConnected => _state == SocketState.connected;
  int? get currentOutletId => _currentOutletId;
  int? get currentFloorId => _currentFloorId;

  /// Initialize socket connection
  void connect({String? token, int? outletId}) {
    // Store for reconnection
    if (token != null) _currentToken = token;
    if (outletId != null) _currentOutletId = outletId;

    // Already connected, skip
    if (_socket != null && _socket!.connected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    _updateState(SocketState.connecting);

    final socketUrl = ApiEndpoints.baseUrl.replaceFirst('/api/v1', '');
    debugPrint('[WebSocket] Connecting to: $socketUrl');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setAuth({'token': _currentToken ?? ''})
          .setQuery({
            if (_currentOutletId != null)
              'outletId': _currentOutletId.toString(),
          })
          .build(),
    );

    _setupEventListeners();
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      debugPrint('[WebSocket] Connected: ${_socket?.id}');
      _updateState(SocketState.connected);
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _stopPolling();

      // Re-join all rooms after connection/reconnection
      _rejoinRooms();
    });

    _socket?.onDisconnect((_) {
      debugPrint('[WebSocket] Disconnected');
      _updateState(SocketState.disconnected);
      // Polling fallback disabled as requested
      // _startPolling();
      _scheduleReconnect();
    });

    _socket?.onConnectError((error) {
      debugPrint('[WebSocket] Connection error: $error');
      _updateState(SocketState.error);
      // Polling fallback disabled as requested
      // _startPolling();
      _scheduleReconnect();
    });

    _socket?.onError((error) {
      debugPrint('[WebSocket] Error: $error');
    });

    // Table updates - handle multiple payload formats
    // Format 1: { tableId, floorId, outletId, status, session, orderId, event, timestamp }
    // Format 2: { tableId, tableNumber, oldStatus, newStatus, changedBy, timestamp }
    _socket?.on(SocketEvents.tableUpdated, (data) {
      debugPrint('[WebSocket] table:updated received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _tableUpdateController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling table:updated: $e');
      }
    });

    // Order updates
    // Format: { type, outletId, orderId, tableId, status }
    _socket?.on(SocketEvents.orderUpdated, (data) {
      debugPrint('[WebSocket] order:updated received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _orderUpdateController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling order:updated: $e');
      }
    });

    // Bill status updates
    // Format: { outletId, orderId, tableId, status, grandTotal }
    _socket?.on(SocketEvents.billStatus, (data) {
      debugPrint('[WebSocket] bill:status received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _billStatusController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling bill:status: $e');
      }
    });

    // Item ready notification
    // Format: { outletId, kotNumber, tableId, tableName, items }
    _socket?.on(SocketEvents.itemReady, (data) {
      debugPrint('[WebSocket] item:ready received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _itemReadyController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling item:ready: $e');
      }
    });

    // KOT updates
    _socket?.on(SocketEvents.kotUpdated, (data) {
      debugPrint('[WebSocket] kot:updated received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _kotUpdateController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling kot:updated: $e');
      }
    });

    // KOT item cancelled
    _socket?.on(SocketEvents.kotItemCancelled, (data) {
      debugPrint('[WebSocket] kot:item_cancelled received: $data');
      try {
        if (data != null) {
          final mapData = Map<String, dynamic>.from(data as Map);
          _kotItemCancelledController.add(mapData);
        }
      } catch (e) {
        debugPrint('[WebSocket] Error handling kot:item_cancelled: $e');
      }
    });
  }

  /// Re-join all rooms after connection/reconnection
  void _rejoinRooms() {
    if (_currentOutletId != null) {
      joinOutlet(_currentOutletId!);
      joinCaptain(_currentOutletId!);
    }
    if (_currentFloorId != null && _currentOutletId != null) {
      joinFloor(_currentOutletId!, _currentFloorId!);
    }
  }

  /// Stop polling when socket reconnects (kept for cleanup)
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocket] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('[WebSocket] Reconnecting... attempt $_reconnectAttempts');
      connect();
    });
  }

  void _updateState(SocketState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Join outlet room for outlet-wide updates
  void joinOutlet(int outletId) {
    _currentOutletId = outletId;
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Joining outlet: $outletId');
      _socket?.emit('join:outlet', outletId);
    }
  }

  /// Leave outlet room
  void leaveOutlet(int outletId) {
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Leaving outlet: $outletId');
      _socket?.emit('leave:outlet', outletId);
    }
  }

  /// Join floor room for table updates
  void joinFloor(int outletId, int floorId) {
    _currentOutletId = outletId;
    _currentFloorId = floorId;
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Joining floor: outlet=$outletId, floor=$floorId');
      _socket?.emit('join:floor', {'outletId': outletId, 'floorId': floorId});
    } else {
      debugPrint('[WebSocket] Not connected, will join floor after connection');
    }
  }

  /// Leave floor room
  void leaveFloor(int outletId, int floorId) {
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Leaving floor: outlet=$outletId, floor=$floorId');
      _socket?.emit('leave:floor', {'outletId': outletId, 'floorId': floorId});
    }
  }

  /// Join captain room for captain-specific updates
  void joinCaptain(int outletId) {
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Joining captain: $outletId');
      _socket?.emit('join:captain', outletId);
    }
  }

  /// Join cashier room
  void joinCashier(int outletId) {
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Joining cashier: $outletId');
      _socket?.emit('join:cashier', outletId);
    }
  }

  /// Join kitchen room
  void joinKitchen(int outletId) {
    if (_socket?.connected == true) {
      debugPrint('[WebSocket] Joining kitchen: $outletId');
      _socket?.emit('join:kitchen', outletId);
    }
  }

  // Legacy methods for backward compatibility
  void joinCaptainRoom(int outletId) => joinCaptain(outletId);
  void joinFloorRoom(int outletId, int floorId) => joinFloor(outletId, floorId);
  void leaveFloorRoom(int outletId, int floorId) =>
      leaveFloor(outletId, floorId);

  void joinRoom(String room) {
    _socket?.emit('join', room);
  }

  void leaveRoom(String room) {
    _socket?.emit('leave', room);
  }

  /// Disconnect socket
  void disconnect() {
    debugPrint('[WebSocket] Disconnecting');
    _reconnectTimer?.cancel();
    _stopPolling();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(SocketState.disconnected);
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _stateController.close();
    _tableUpdateController.close();
    _orderUpdateController.close();
    _billStatusController.close();
    _itemReadyController.close();
    _kotUpdateController.close();
    _kotItemCancelledController.close();
  }
}

// Provider for WebSocket service (singleton)
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
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

// Stream providers for real-time updates
final tableUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.tableUpdates;
});

final orderUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.orderUpdates;
});

final billStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.billStatus;
});

final itemReadyProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.itemReady;
});

final kotUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.kotUpdates;
});

final kotItemCancelledProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.kotItemCancelled;
});
