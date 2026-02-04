import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../data/dummy_data/dummy_users.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
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
  AuthNotifier() : super(AuthState.initial());

  void setLoginMode(LoginMode mode) {
    state = state.copyWith(loginMode: mode);
  }

  Future<bool> loginWithPasscode(String passcode) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = DummyUsers.findByPasscode(passcode);
    
    if (user != null) {
      state = AuthState.authenticated(
        user: user.copyWith(lastLoginAt: DateTime.now()),
        token: 'dummy_token_${user.id}',
        refreshToken: 'dummy_refresh_${user.id}',
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid passcode. Please try again.',
      );
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = DummyUsers.findByPin(pin);
    
    if (user != null) {
      state = AuthState.authenticated(
        user: user.copyWith(lastLoginAt: DateTime.now()),
        token: 'dummy_token_${user.id}',
        refreshToken: 'dummy_refresh_${user.id}',
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid PIN. Please try again.',
      );
      return false;
    }
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = DummyUsers.findByCredentials(username, password);
    
    if (user != null) {
      state = AuthState.authenticated(
        user: user.copyWith(lastLoginAt: DateTime.now()),
        token: 'dummy_token_${user.id}',
        refreshToken: 'dummy_refresh_${user.id}',
      );
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid username or password.',
      );
      return false;
    }
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isSessionRestoring: true);
    
    // Simulate checking for stored session
    await Future.delayed(const Duration(milliseconds: 300));
    
    // For now, just mark as unauthenticated
    state = AuthState.unauthenticated();
  }

  void logout() {
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }
}
