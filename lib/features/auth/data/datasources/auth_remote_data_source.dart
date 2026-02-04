import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> loginWithEmail(LoginWithEmailRequest request);
  Future<LoginResponse> loginWithPin(LoginWithPinRequest request);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<LoginResponse> loginWithEmail(LoginWithEmailRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndPoints.login,
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  @override
  Future<LoginResponse> loginWithPin(LoginWithPinRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndPoints.loginWithPin,
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('No response data received from server');
      }

      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } on TypeError catch (e) {
      throw Exception('Invalid response format: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndPoints.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return Exception(data?['message'] ?? 'Invalid credentials');
        } else if (statusCode == 403) {
          return Exception('Access denied');
        } else if (statusCode == 404) {
          return Exception('Service not found');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }
        return Exception(data?['message'] ?? 'An error occurred');

      case DioExceptionType.cancel:
        return Exception('Request cancelled');

      case DioExceptionType.connectionError:
        return Exception('No internet connection');

      default:
        return Exception('An unexpected error occurred');
    }
  }
}
