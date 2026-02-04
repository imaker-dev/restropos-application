import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_manager.dart';
import '../../features/auth/data/services/auth_websocket_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final appInitializationServiceProvider = Provider<AppInitializationService>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  final authWebSocketService = ref.watch(authWebSocketServiceProvider);
  final authNotifier = ref.watch(authProvider.notifier);
  return AppInitializationService(cacheManager, authWebSocketService, authNotifier);
});

class AppInitializationService {
  final CacheManager _cacheManager;
  final AuthWebSocketService _authWebSocketService;
  final AuthNotifier _authNotifier;

  AppInitializationService(this._cacheManager, this._authWebSocketService, this._authNotifier);

  Future<void> initialize() async {
    // Initialize cache manager
    await _cacheManager.init();
    
    // Initialize WebSocket user updates
    _authWebSocketService.initializeUserUpdates((user) {
      // Update auth state when user data changes
      _authNotifier.updateUser(user);
    });
    
    // Try to restore session
    await _authNotifier.restoreSession();
  }

  Future<void> dispose() async {
    // Clean up resources
    _authWebSocketService.unsubscribeFromUserChannel('current');
  }
}
