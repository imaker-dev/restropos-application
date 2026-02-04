import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../domain/entities/user.dart';
import 'real_auth_service.dart';

final authWebSocketServiceProvider = Provider<AuthWebSocketService>((ref) {
  final websocketClient = ref.watch(websocketClientProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  final realAuthService = ref.watch(realAuthServiceProvider);
  return AuthWebSocketService(websocketClient, cacheManager, realAuthService);
});

class AuthWebSocketService {
  final WebSocketClient _websocketClient;
  final CacheManager _cacheManager;
  final RealAuthService _realAuthService;

  AuthWebSocketService(this._websocketClient, this._cacheManager, this._realAuthService);

  void initializeUserUpdates(void Function(User) onUserUpdate) {
    // Listen to WebSocket events for user updates
    _websocketClient.events.listen((event) {
      switch (event.event) {
        case 'USER_UPDATED':
        case 'PERMISSIONS_UPDATED':
        case 'ROLE_UPDATED':
          _handleUserUpdate(event, onUserUpdate);
          break;
        case 'USER_LOGGED_OUT':
          _handleUserLogout();
          break;
        case 'TOKEN_REFRESHED':
          _handleTokenRefresh(event);
          break;
      }
    });
  }

  void _handleUserUpdate(WebSocketEvent event, void Function(User) onUserUpdate) {
    // Invalidate user cache when user data is updated
    _cacheManager.removeMemory('current_user');
    
    // Fetch fresh user data
    _realAuthService.getCurrentUser().then((response) {
      if (response.success && response.user != null) {
        onUserUpdate(response.user!);
      }
    }).catchError((error) {
      // If API fails, continue with cached data
      print('Failed to refresh user data: $error');
    });
  }

  void _handleUserLogout() {
    // Clear user cache when logged out from another device
    _cacheManager.clearBox('user_cache');
    _cacheManager.remove('general_cache', 'auth_token');
    _cacheManager.remove('general_cache', 'refresh_token');
    
    // Disconnect WebSocket
    _websocketClient.disconnect();
  }

  void _handleTokenRefresh(WebSocketEvent event) {
    // Handle token refresh from WebSocket
    if (event.data is Map<String, dynamic>) {
      final data = event.data as Map<String, dynamic>;
      final newToken = data['token'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      
      if (newToken != null) {
        _cacheManager.set('general_cache', 'auth_token', newToken);
      }
      
      if (newRefreshToken != null) {
        _cacheManager.set('general_cache', 'refresh_token', newRefreshToken);
      }
    }
  }

  void subscribeToUserChannel(String userId) {
    // Subscribe to user-specific channel for real-time updates
    _websocketClient.subscribe('user_$userId');
  }

  void unsubscribeFromUserChannel(String userId) {
    // Unsubscribe from user-specific channel
    _websocketClient.unsubscribe('user_$userId');
  }

  void sendUserActivity(String activity, Map<String, dynamic>? data) {
    // Send user activity updates
    _websocketClient.emit('user_activity', {
      'activity': activity,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listen for connection status changes
  void listenToConnectionStatus(void Function(ConnectionStatus) onStatusChange) {
    _websocketClient.connectionStatus.listen(onStatusChange);
  }

  // Get current connection status
  ConnectionStatus get connectionStatus => _websocketClient.status;

  // Manual reconnection
  void reconnect() {
    _realAuthService.getStoredToken().then((token) {
      if (token != null) {
        _websocketClient.connect(token: token);
      }
    });
  }
}
