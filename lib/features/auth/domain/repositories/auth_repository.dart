import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> loginWithPin({
    required String employeeCode,
    required String pin,
  });

  Future<void> logout();
  
  Future<String?> getStoredToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class AuthResult {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  const AuthResult({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
  });

  bool get isSuccess => user != null && accessToken != null;
  bool get isFailure => error != null;

  factory AuthResult.success({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(error: error);
  }
}
