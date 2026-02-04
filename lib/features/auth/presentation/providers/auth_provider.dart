import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../data/dummy_data/dummy_users.dart';
import '../../data/services/real_auth_service.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/providers/connectivity_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final loginModeProvider = Provider<LoginMode>((ref) {
  return ref.watch(authProvider).loginMode;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial());

  CacheManager get _cacheManager => _ref.read(cacheManagerProvider);
  RealAuthService get _realAuthService => _ref.read(realAuthServiceProvider);
  bool get _isConnected => _ref.read(connectivityProvider).isOnline;

  void setLoginMode(LoginMode mode) {
    state = state.copyWith(loginMode: mode);
  }

  Future<bool> loginWithPasscode(String passcode) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (!_isConnected) {
        // Fallback to dummy data when offline
        final user = DummyUsers.findByPasscode(passcode);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid passcode. Please try again.',
          );
          return false;
        }
      }

      // Try real API first
      try {
        final response = await _realAuthService.loginWithPasscode(passcode);

        if (response.success && response.user != null && response.token != null) {
          state = AuthState.authenticated(
            user: response.user!,
            token: response.token!,
            refreshToken: response.refreshToken,
          );
          await _cacheManager.cacheUser(response.user!.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: response.message ?? 'Login failed',
          );
          return false;
        }
      } catch (e) {
        // Fallback to dummy data if API fails
        final user = DummyUsers.findByPasscode(passcode);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid passcode. Please try again.',
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (!_isConnected) {
        // Fallback to dummy data when offline
        final user = DummyUsers.findByPin(pin);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid PIN. Please try again.',
          );
          return false;
        }
      }

      // Try real API first
      try {
        final response = await _realAuthService.loginWithPin(pin);

        if (response.success && response.user != null && response.token != null) {
          state = AuthState.authenticated(
            user: response.user!,
            token: response.token!,
            refreshToken: response.refreshToken,
          );
          await _cacheManager.cacheUser(response.user!.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: response.message ?? 'Login failed',
          );
          return false;
        }
      } catch (e) {
        // Fallback to dummy data if API fails
        final user = DummyUsers.findByPin(pin);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid PIN. Please try again.',
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (!_isConnected) {
        // Fallback to dummy data when offline
        final user = DummyUsers.findByCredentials(username, password);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid username or password.',
          );
          return false;
        }
      }

      // Try real API first
      try {
        final response = await _realAuthService.loginWithCredentials(username, password);

        if (response.success && response.user != null && response.token != null) {
          state = AuthState.authenticated(
            user: response.user!,
            token: response.token!,
            refreshToken: response.refreshToken,
          );
          await _cacheManager.cacheUser(response.user!.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: response.message ?? 'Login failed',
          );
          return false;
        }
      } catch (e) {
        // Fallback to dummy data if API fails
        final user = DummyUsers.findByCredentials(username, password);

        if (user != null) {
          state = AuthState.authenticated(
            user: user.copyWith(lastLoginAt: DateTime.now()),
            token: 'dummy_token_${user.id}',
            refreshToken: 'dummy_refresh_${user.id}',
          );
          await _cacheManager.cacheUser(user.toJson());
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid username or password.',
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isSessionRestoring: true);

    try {
      // Use real auth service to restore session
      final restored = await _realAuthService.restoreSession();

      if (restored) {
        // Get stored user data
        final user = await _realAuthService.getStoredUser();
        final token = await _realAuthService.getStoredToken();
        final refreshToken = await _realAuthService.getStoredRefreshToken();

        if (user != null && token != null) {
          state = AuthState.authenticated(
            user: user,
            token: token,
            refreshToken: refreshToken,
          );
          return;
        }
      }

      // If restoration failed, mark as unauthenticated
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated();
    } finally {
      state = state.copyWith(isSessionRestoring: false);
    }
  }

  Future<void> logout() async {
    try {
      if (_isConnected && state.token != null) {
        await _realAuthService.logout();
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    await _cacheManager.clearBox('user_cache');
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  void updateUser(User user) {
    if (state.isAuthenticated) {
      state = state.copyWith(user: user);
    }
  }

  void setAuthenticatedState(User user, String token, String? refreshToken) {
    state = AuthState.authenticated(
      user: user,
      token: token,
      refreshToken: refreshToken,
    );
  }
}
