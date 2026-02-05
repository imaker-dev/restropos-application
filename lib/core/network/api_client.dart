import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restro/core/network/api_endpoints.dart';
import 'package:restro/core/auth/app_preferences.dart';
import '../constants/app_constants.dart';

final storedTokenProvider = FutureProvider<String?>((ref) async {
  return await AppPreferences.getSessionToken();
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    LogInterceptor(requestBody: true, responseBody: true, error: true),
    AuthInterceptor(),
    RetryInterceptor(dio),
  ]);

  return dio;
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login endpoints
    if (options.path.contains('/auth/login')) {
      handler.next(options);
      return;
    }

    try {
      final token = await AppPreferences.getSessionToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Continue without token if storage fails
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear token on 401 - session expired
      await AppPreferences.clearSessionToken();
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor(this.dio, {this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final options = err.requestOptions;
      final retryCount = options.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        options.extra['retryCount'] = retryCount + 1;

        // Exponential backoff
        await Future.delayed(
          Duration(milliseconds: 100 * ((retryCount as int) + 1)),
        );

        try {
          final response = await dio.fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          // Continue to error handler
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
