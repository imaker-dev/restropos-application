import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/auth_models.dart';

/// Repository for Authentication operations
class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  /// Login with email and password
  Future<ApiResult<LoginResponse>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);
    return _api.post(
      ApiEndpoints.login,
      data: request.toJson(),
      parser: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Login with PIN
  Future<ApiResult<PinLoginResponse>> loginWithPin({
    required String employeeCode,
    required String pin,
    required int outletId,
  }) async {
    final request = PinLoginRequest(
      employeeCode: employeeCode,
      pin: pin,
      outletId: outletId,
    );
    return _api.post(
      ApiEndpoints.loginPin,
      data: request.toJson(),
      parser: (json) => PinLoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get current user profile
  Future<ApiResult<ApiUser>> getProfile() async {
    return _api.get(
      ApiEndpoints.me,
      parser: (json) => ApiUser.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get user permissions
  Future<ApiResult<PermissionsResponse>> getPermissions() async {
    return _api.get(
      ApiEndpoints.myPermissions,
      parser: (json) => PermissionsResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthRepository(api);
});
