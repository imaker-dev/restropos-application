import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restro/core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../models/auth_response.dart';
import '../../domain/entities/user.dart';

final realAuthServiceProvider = Provider<RealAuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final websocketClient = ref.watch(websocketClientProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return RealAuthService(dio, websocketClient, cacheManager);
});

class RealAuthService {
  final Dio _dio;
  final WebSocketClient _websocketClient;
  final CacheManager _cacheManager;

  RealAuthService(this._dio, this._websocketClient, this._cacheManager);

  Future<AuthResponse> loginWithPasscode(String passcode) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'passcode': passcode,
          'loginType': 'passcode',
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        if (authResponse.success && authResponse.user != null && authResponse.token != null) {
          // Cache user data
          await _cacheManager.cacheUser(authResponse.user!.toJson());
          
          // Cache tokens
          await _cacheManager.set('general_cache', 'auth_token', authResponse.token!);
          if (authResponse.refreshToken != null) {
            await _cacheManager.set('general_cache', 'refresh_token', authResponse.refreshToken!);
          }
          
          // Connect WebSocket with token
          _websocketClient.connect(token: authResponse.token);
          
          return authResponse;
        } else {
          throw ApiException(
            message: authResponse.message ?? 'Login failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ApiException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> loginWithPin(String pin) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'pin': pin,
          'loginType': 'pin',
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        if (authResponse.success && authResponse.user != null && authResponse.token != null) {
          // Cache user data
          await _cacheManager.cacheUser(authResponse.user!.toJson());
          
          // Cache tokens
          await _cacheManager.set('general_cache', 'auth_token', authResponse.token!);
          if (authResponse.refreshToken != null) {
            await _cacheManager.set('general_cache', 'refresh_token', authResponse.refreshToken!);
          }
          
          // Connect WebSocket with token
          _websocketClient.connect(token: authResponse.token);
          
          return authResponse;
        } else {
          throw ApiException(
            message: authResponse.message ?? 'Login failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ApiException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> loginWithCredentials(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'loginType': 'credentials',
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        if (authResponse.success && authResponse.user != null && authResponse.token != null) {
          // Cache user data
          await _cacheManager.cacheUser(authResponse.user!.toJson());
          
          // Cache tokens
          await _cacheManager.set('general_cache', 'auth_token', authResponse.token!);
          if (authResponse.refreshToken != null) {
            await _cacheManager.set('general_cache', 'refresh_token', authResponse.refreshToken!);
          }
          
          // Connect WebSocket with token
          _websocketClient.connect(token: authResponse.token);
          
          return authResponse;
        } else {
          throw ApiException(
            message: authResponse.message ?? 'Login failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ApiException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> getCurrentUser() async {
    try {
      print('🔍 API CALL: Getting current user...');
      print('📡 Request: GET /auth/me');
      print('🌐 Full URL: ${_dio.options.baseUrl}/auth/me');
      print('🔑 Authorization: ${_dio.options.headers['Authorization']}');
      
      final response = await _dio.get(ApiEndPoints.profile);
      
      print('✅ Response Status: ${response.statusCode}');
      print('📄 Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        print('👤 User Data: ${authResponse.user?.toJson()}');
        print('🔑 Token: ${authResponse.token}');
        print('🔄 Refresh Token: ${authResponse.refreshToken}');
        print('✅ Success: ${authResponse.success}');
        print('💬 Message: ${authResponse.message}');
        
        if (authResponse.success && authResponse.user != null) {
          // Update cached user data
          await _cacheManager.cacheUser(authResponse.user!.toJson());
          print('💾 User data cached successfully');
        }
        
        return authResponse;
      } else {
        throw ApiException(
          message: 'Failed to fetch user data',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ DioException in getCurrentUser: ${e.message}');
      print('📊 Error Response: ${e.response?.data}');
      print('🔢 Status Code: ${e.response?.statusCode}');
      throw ApiException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('💥 Unexpected Error in getCurrentUser: ${e.toString()}');
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    try {
      // Call logout API
      await _dio.post('/auth/logout');
      
      // Disconnect WebSocket
      _websocketClient.disconnect();
      
      // Clear cached data
      await _cacheManager.clearBox('user_cache');
      await _cacheManager.remove('general_cache', 'auth_token');
      await _cacheManager.remove('general_cache', 'refresh_token');
      
    } catch (e) {
      // Continue with cleanup even if API call fails
      _websocketClient.disconnect();
      await _cacheManager.clearBox('user_cache');
      await _cacheManager.remove('general_cache', 'auth_token');
      await _cacheManager.remove('general_cache', 'refresh_token');
    }
  }

  Future<String?> getStoredToken() async {
    return await _cacheManager.get('general_cache', 'auth_token');
  }

  Future<String?> getStoredRefreshToken() async {
    return await _cacheManager.get('general_cache', 'refresh_token');
  }

  Future<User?> getStoredUser() async {
    final userData = await _cacheManager.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<bool> restoreSession() async {
    try {
      print('🔄 SESSION RESTORATION: Starting...');
      
      // Get stored token
      final token = await getStoredToken();
      print('🔑 Stored Token: ${token != null ? "Found" : "Not found"}');
      if (token == null) return false;
      
      // Get stored user
      final user = await getStoredUser();
      print('👤 Stored User: ${user != null ? "Found" : "Not found"}');
      if (user == null) return false;
      
      // Connect WebSocket
      print('🌐 Connecting WebSocket...');
      _websocketClient.connect(token: token);
      
      // Try to refresh user data from API
      try {
        print('🔄 Refreshing user data from API...');
        final response = await getCurrentUser();
        print('✅ Session restored successfully');
        return response.success && response.user != null;
      } catch (e) {
        print('⚠️ API refresh failed, using stored data: $e');
        // If API fails, use stored data
        return true;
      }
      
    } catch (e) {
      return false;
    }
  }

  // Listen to WebSocket events for user updates
  void listenToUserUpdates(void Function(User) onUserUpdate) {
    _websocketClient.events.listen((event) {
      if (event.event == 'USER_UPDATED' || event.event == 'PERMISSIONS_UPDATED') {
        // Refresh user data when updated via WebSocket
        getCurrentUser().then((response) {
          if (response.success && response.user != null) {
            onUserUpdate(response.user!);
          }
        });
      }
    });
  }
}
