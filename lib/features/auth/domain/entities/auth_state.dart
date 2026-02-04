import 'package:equatable/equatable.dart';
import 'user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

enum LoginMode {
  credentials,
  pin,
  passcode,
  cardSwipe,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? errorMessage;
  final LoginMode loginMode;
  final bool isSessionRestoring;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.refreshToken,
    this.errorMessage,
    this.loginMode = LoginMode.passcode,
    this.isSessionRestoring = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? refreshToken,
    String? errorMessage,
    LoginMode? loginMode,
    bool? isSessionRestoring,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: errorMessage,
      loginMode: loginMode ?? this.loginMode,
      isSessionRestoring: isSessionRestoring ?? this.isSessionRestoring,
    );
  }

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated({
    required User user,
    required String token,
    String? refreshToken,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
      refreshToken: refreshToken,
    );
  }

  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        token,
        refreshToken,
        errorMessage,
        loginMode,
        isSessionRestoring,
      ];
}
