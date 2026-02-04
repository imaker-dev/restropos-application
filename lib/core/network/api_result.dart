import 'package:dio/dio.dart';

/// Standardized API result wrapper following the API contract
/// { success: boolean, message?: string, data?: any }
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get data => switch (this) {
    ApiSuccess<T> s => s.data,
    ApiFailure<T> _ => null,
  };

  String? get message => switch (this) {
    ApiSuccess<T> s => s.message,
    ApiFailure<T> f => f.message,
  };

  R when<R>({
    required R Function(T data, String? message) success,
    required R Function(String message, int? statusCode, dynamic error) failure,
  }) {
    return switch (this) {
      ApiSuccess<T> s => success(s.data, s.message),
      ApiFailure<T> f => failure(f.message, f.statusCode, f.error),
    };
  }

  R maybeWhen<R>({
    R Function(T data, String? message)? success,
    R Function(String message, int? statusCode, dynamic error)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      ApiSuccess<T> s => success?.call(s.data, s.message) ?? orElse(),
      ApiFailure<T> f =>
        failure?.call(f.message, f.statusCode, f.error) ?? orElse(),
    };
  }

  void whenOrNull({
    void Function(T data, String? message)? success,
    void Function(String message, int? statusCode, dynamic error)? failure,
  }) {
    switch (this) {
      case ApiSuccess<T> s:
        success?.call(s.data, s.message);
      case ApiFailure<T> f:
        failure?.call(f.message, f.statusCode, f.error);
    }
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  @override
  final T data;
  @override
  final String? message;

  const ApiSuccess(this.data, {this.message});
}

final class ApiFailure<T> extends ApiResult<T> {
  @override
  final String message;
  final int? statusCode;
  final dynamic error;

  const ApiFailure(this.message, {this.statusCode, this.error});
}

/// Extension to parse API responses
extension ApiResultParser on Response {
  ApiResult<T> toApiResult<T>(T Function(dynamic json) parser) {
    try {
      final body = data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      final message = body['message'] as String?;

      if (success) {
        final responseData = body['data'];
        if (responseData == null) {
          return ApiFailure('Response data is null', statusCode: statusCode);
        }
        try {
          return ApiSuccess(parser(responseData), message: message);
        } catch (parseError) {
          return ApiFailure(
            'Failed to parse response data: $parseError',
            statusCode: statusCode,
            error: parseError,
          );
        }
      } else {
        return ApiFailure(message ?? 'Request failed', statusCode: statusCode);
      }
    } catch (e) {
      return ApiFailure(
        'Failed to parse response: $e',
        statusCode: statusCode,
        error: e,
      );
    }
  }

  ApiResult<List<T>> toApiResultList<T>(
    T Function(Map<String, dynamic> json) parser,
  ) {
    try {
      final body = data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      final message = body['message'] as String?;

      if (success) {
        final responseData = body['data'] as List?;
        final items =
            responseData
                ?.map((e) => parser(e as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiSuccess(items, message: message);
      } else {
        return ApiFailure(message ?? 'Request failed', statusCode: statusCode);
      }
    } catch (e) {
      return ApiFailure(
        'Failed to parse response',
        statusCode: statusCode,
        error: e,
      );
    }
  }
}

/// Extension to handle DioException
extension DioExceptionHandler on DioException {
  ApiFailure<T> toApiFailure<T>() {
    String message;
    switch (type) {
      case DioExceptionType.connectionTimeout:
        message =
            'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        message = 'Request timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        message = 'Server took too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final body = response?.data;
        if (body is Map<String, dynamic>) {
          message = body['message'] as String? ?? 'Request failed';
        } else if (statusCode == 401) {
          message = 'Session expired. Please login again.';
        } else if (statusCode == 403) {
          message = 'You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Request failed. Please try again.';
        }
        return ApiFailure(message, statusCode: statusCode, error: this);
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
      case DioExceptionType.badCertificate:
        message = 'Security certificate error.';
      case DioExceptionType.unknown:
        message = 'An unexpected error occurred. Please try again.';
    }
    return ApiFailure(message, statusCode: response?.statusCode, error: this);
  }
}
