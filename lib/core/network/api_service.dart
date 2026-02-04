import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_result.dart';

/// Base API service with common request handling
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.toApiResult(parser);
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }

  Future<ApiResult<List<T>>> getList<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.toApiResultList(parser);
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParams,
      );
      return response.toApiResult(parser);
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParams,
      );
      return response.toApiResult(parser);
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParams,
      );
      return response.toApiResult(parser);
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }

  Future<ApiResult<bool>> deleteVoid(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (success) {
        return const ApiSuccess(true);
      }
      return ApiFailure(body['message'] as String? ?? 'Delete failed');
    } on DioException catch (e) {
      return e.toApiFailure();
    }
  }
}

/// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

/// Default outlet ID provider (can be overridden after login)
final outletIdProvider = StateProvider<int>(
  (ref) => ApiEndpoints.defaultOutletId,
);
