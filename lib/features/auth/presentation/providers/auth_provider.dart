import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/providers/auth_data_providers.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
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
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  void setLoginMode(LoginMode mode) {
    state = state.copyWith(loginMode: mode);
  }

  Future<bool> loginWithPasscode(
    String passcode, {
    String? employeeCode,
  }) async {
    // For PIN-based login, we need both employee code and PIN
    // If no employee code provided, use a default one for testing
    // In production, this should come from a separate input or stored preference
    return loginWithPin(
      pin: passcode,
      employeeCode:
          employeeCode ?? 'CAP0023', // Default employee code for testing
    );
  }

  Future<bool> loginWithPin({required String pin, String? employeeCode}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // If no employee code provided, use pin as employee code for backward compatibility
      final result = await _repository.loginWithPin(
        employeeCode: employeeCode ?? 'CAP0023',
        pin: pin,
      );

      if (result.isSuccess) {
        state = AuthState.authenticated(
          user: result.user!,
          token: result.accessToken!,
          refreshToken: result.refreshToken!,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: result.error ?? 'Login failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
      return false;
    }
  }

  Future<bool> loginWithCredentials(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final result = await _repository.loginWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        state = AuthState.authenticated(
          user: result.user!,
          token: result.accessToken!,
          refreshToken: result.refreshToken!,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              result.error ?? 'Invalid credentials. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
      return false;
    }
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isSessionRestoring: true);

    try {
      final token = await _repository.getStoredToken();

      if (token != null && token.isNotEmpty) {
        // Token exists, could fetch user profile here
        // For now, just mark as authenticated with minimal state
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isSessionRestoring: false,
        );
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  void setError(String message) {
    state = state.copyWith(status: AuthStatus.error, errorMessage: message);
  }
}
