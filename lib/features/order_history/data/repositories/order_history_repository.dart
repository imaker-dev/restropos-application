import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/order_history_models.dart';

/// Repository for Order History operations
class OrderHistoryRepository {
  final ApiService _api;

  OrderHistoryRepository(this._api);

  /// Get order history for an outlet
  Future<ApiResult<List<OrderHistory>>> getOrderHistory(int outletId) async {
    return _api.getList(
      ApiEndpoints.orderHistory(outletId),
      parser: OrderHistory.fromJson,
    );
  }

  /// Get order history by date range
  Future<ApiResult<List<OrderHistory>>> getOrderHistoryByDate({
    required int outletId,
    required String fromDate,
    required String toDate,
  }) async {
    return _api.getList(
      ApiEndpoints.orderHistoryByDate(outletId, fromDate, toDate),
      parser: OrderHistory.fromJson,
    );
  }

  /// Get order history summary
  Future<ApiResult<OrderHistorySummary>> getOrderHistorySummary(int outletId) async {
    return _api.get(
      ApiEndpoints.orderHistorySummary(outletId),
      parser: (json) => OrderHistorySummary.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get order by ID
  Future<ApiResult<OrderHistory>> getOrderById(int orderId) async {
    return _api.get(
      ApiEndpoints.orderById(orderId),
      parser: (json) => OrderHistory.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get order history with pagination
  Future<ApiResult<List<OrderHistory>>> getOrderHistoryPaginated({
    required int outletId,
    int page = 1,
    int limit = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    String url = ApiEndpoints.orderHistory(outletId);
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status!;
    if (fromDate != null) queryParams['from'] = fromDate!;
    if (toDate != null) queryParams['to'] = toDate!;

    return _api.getList(
      url,
      parser: OrderHistory.fromJson,
      queryParams: queryParams,
    );
  }

  /// Search order history
  Future<ApiResult<List<OrderHistory>>> searchOrders({
    required int outletId,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return _api.getList(
      '${ApiEndpoints.orderHistory(outletId)}?search=$query',
      parser: OrderHistory.fromJson,
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
  }

  /// Get order statistics
  Future<ApiResult<Map<String, dynamic>>> getOrderStatistics(int outletId) async {
    return _api.get(
      '${ApiEndpoints.orderHistory(outletId)}/statistics',
      parser: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get today's orders
  Future<ApiResult<List<OrderHistory>>> getTodayOrders(int outletId) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _api.getList(
      '${ApiEndpoints.orderHistory(outletId)}?date=$todayString',
      parser: OrderHistory.fromJson,
    );
  }

  /// Get this week's orders
  Future<ApiResult<List<OrderHistory>>> getThisWeekOrders(int outletId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartString = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final weekEndString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    return _api.getList(
      '${ApiEndpoints.orderHistoryByDate(outletId, weekStartString, weekEndString)}',
      parser: OrderHistory.fromJson,
    );
  }

  /// Get this month's orders
  Future<ApiResult<List<OrderHistory>>> getThisMonthOrders(int outletId) async {
    final now = DateTime.now();
    final monthStartString = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final monthEndString = '${now.year}-${now.month.toString().padLeft(2, '0')}-31';
    
    return _api.getList(
      '${ApiEndpoints.orderHistoryByDate(outletId, monthStartString, monthEndString)}',
      parser: OrderHistory.fromJson,
    );
  }
}

/// Provider for OrderHistoryRepository
final orderHistoryRepositoryProvider = Provider<OrderHistoryRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return OrderHistoryRepository(api);
});
