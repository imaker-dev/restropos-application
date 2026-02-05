import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/auth/app_preferences.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';


final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

final currentUserProvider = Provider<ApiUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final loginModeProvider = Provider<LoginMode>((ref) {
  return ref.watch(authProvider).loginMode;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).accessToken;
});

final userPermissionsProvider = Provider<List<String>>((ref) {
  return ref.watch(authProvider).permissions;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(AuthState.initial());

  void setLoginMode(LoginMode mode) {
    state = state.copyWith(loginMode: mode);
  }

  /// Login with passcode (maps to email login for now)
  Future<bool> loginWithPasscode(String passcode) async {
    // For passcode login, we use it as a PIN with a default employee code
    return loginWithPin('CAPTAIN', passcode);
  }

  /// Login with credentials (username/password)
  Future<bool> loginWithCredentials(String username, String password) async {
    return loginWithEmail(username, password);
  }

  /// Login with email and password
  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _repository.loginWithEmail(
      email: email,
      password: password,
    );

    return result.when(
      success: (data, message) async {
        await AppPreferences.setSessionToken(data.accessToken);
        await AppPreferences.setUserId(data.user.id.toString());

        // Update outlet ID
        final outletId =
            data.user.primaryOutletId ?? ApiEndpoints.defaultOutletId;
        _ref.read(outletIdProvider.notifier).state = outletId;

        // Fetch permissions
        final permissions = await _fetchPermissions();

        state = AuthState.authenticated(
          user: data.user,
          accessToken: data.accessToken,
          permissions: permissions,
          outletId: outletId,
        );

        // Connect WebSocket for real-time updates
        _ref
            .read(webSocketServiceProvider)
            .connect(token: data.accessToken, outletId: outletId);

        return true;
      },
      failure: (message, statusCode, error) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: message);
        return false;
      },
    );
  }

  /// Login with PIN
  Future<bool> loginWithPin(String employeeCode, String pin) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final outletId = _ref.read(outletIdProvider);

    final result = await _repository.loginWithPin(
      employeeCode: employeeCode,
      pin: pin,
      outletId: outletId,
    );

    return result.when(
      success: (data, message) async {
        await AppPreferences.setSessionToken(data.accessToken);

        // Fetch profile and permissions
        final profileResult = await _repository.getProfile();

        return profileResult.when(
          success: (user, _) async {
            await AppPreferences.setUserId(user.id.toString());

            final permissions = await _fetchPermissions();

            final userOutletId = user.primaryOutletId ?? outletId;
            state = AuthState.authenticated(
              user: user,
              accessToken: data.accessToken,
              permissions: permissions,
              outletId: userOutletId,
            );

            // Connect WebSocket for real-time updates
            _ref
                .read(webSocketServiceProvider)
                .connect(token: data.accessToken, outletId: userOutletId);

            return true;
          },
          failure: (msg, code, err) {
            state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
            return false;
          },
        );
      },
      failure: (message, statusCode, error) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: message);
        return false;
      },
    );
  }

  /// Fetch user permissions
  Future<List<String>> _fetchPermissions() async {
    final result = await _repository.getPermissions();
    return result.when(
      success: (data, _) => data.permissions,
      failure: (_, __, ___) => <String>[],
    );
  }

  /// Restore session from stored token
  Future<void> restoreSession() async {
    if (state.isSessionRestoring || state.isAuthenticated) {
      return;
    }

    state = state.copyWith(isSessionRestoring: true);

    try {
      final token = await AppPreferences.getSessionToken();

      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      // We have a token, try to get the profile
      // Note: The token will be used by the API client interceptor
      final profileResult = await _repository.getProfile();

      await profileResult.when(
        success: (user, _) async {
          // Fetch permissions in parallel with other operations
          final permissionsFuture = _fetchPermissions();
          final outletId = user.primaryOutletId ?? ApiEndpoints.defaultOutletId;
          _ref.read(outletIdProvider.notifier).state = outletId;
          
          final permissions = await permissionsFuture;

          state = AuthState.authenticated(
            user: user,
            accessToken: token,
            permissions: permissions,
            outletId: outletId,
          );
        },
        failure: (_, __, ___) async {
          // Token is invalid, clear storage
          await _clearStoredSession();
          state = AuthState.unauthenticated();
        },
      );
    } catch (e) {
      await _clearStoredSession();
      state = AuthState.unauthenticated();
    }
  }

  /// Clear stored session data
  Future<void> _clearStoredSession() async {
    await AppPreferences.clearSessionToken();
    await AppPreferences.clearUserId();
  }

  /// Logout
  Future<void> logout() async {
    // Disconnect WebSocket
    _ref.read(webSocketServiceProvider).disconnect();

    await _clearStoredSession();
    state = AuthState.unauthenticated();
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Update outlet ID (for multi-outlet users)
  void setOutletId(int outletId) {
    _ref.read(outletIdProvider.notifier).state = outletId;
    state = state.copyWith(outletId: outletId);
  }
}
