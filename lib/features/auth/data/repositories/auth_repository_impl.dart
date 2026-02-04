import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SharedPreferences _sharedPreferences;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SharedPreferences sharedPreferences,
  }) : _remoteDataSource = remoteDataSource,
       _sharedPreferences = sharedPreferences;

  @override
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginWithEmailRequest(email: email, password: password);

      final response = await _remoteDataSource.loginWithEmail(request);

      if (!response.success || response.data == null) {
        return AuthResult.failure(response.message);
      }

      final data = response.data!;
      final user = data.user.toEntity();

      // Save tokens
      await saveToken(data.accessToken);
      await _sharedPreferences.setString(
        AppConstants.refreshTokenKey,
        data.refreshToken,
      );

      return AuthResult.success(
        user: user,
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
      );
    } on Exception catch (e) {
      return AuthResult.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  @override
  Future<AuthResult> loginWithPin({
    required String employeeCode,
    required String pin,
  }) async {
    try {
      final request = LoginWithPinRequest(
        employeeCode: employeeCode,
        pin: pin,
        outletId: AppConstants.defaultOutletId,
      );

      final response = await _remoteDataSource.loginWithPin(request);

      if (!response.success || response.data == null) {
        return AuthResult.failure(response.message);
      }

      final data = response.data!;
      final user = data.user.toEntity();

      // Save tokens
      await saveToken(data.accessToken);
      await _sharedPreferences.setString(
        AppConstants.refreshTokenKey,
        data.refreshToken,
      );

      return AuthResult.success(
        user: user,
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
      );
    } on TypeError catch (e) {
      return AuthResult.failure(
        'Invalid response from server. Please try again.',
      );
    } on Exception catch (e) {
      return AuthResult.failure(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await clearToken();
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return _sharedPreferences.getString(AppConstants.authTokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await _sharedPreferences.setString(AppConstants.authTokenKey, token);
  }

  @override
  Future<void> clearToken() async {
    await _sharedPreferences.remove(AppConstants.authTokenKey);
    await _sharedPreferences.remove(AppConstants.refreshTokenKey);
  }
}
