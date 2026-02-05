import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restro/core/network/api_service.dart';
import 'package:restro/features/order_history/data/repositories/order_history_repository.dart';
import 'package:restro/features/order_history/domain/entities/order_history_entity.dart';
import 'package:restro/features/order_history/data/static/static_order_history_data.dart';


// Order History State
class OrderHistoryState {
  final bool isLoading;
  final List<OrderHistoryEntity> orders;
  final OrderHistorySummaryEntity? summary;
  final String? error;
  final String? selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int currentPage;
  final bool hasMoreData;
  final String searchQuery;
  final bool useStaticData;

  const OrderHistoryState({
    this.isLoading = false,
    this.orders = const [],
    this.summary,
    this.error,
    this.selectedStatus,
    this.fromDate,
    this.toDate,
    this.currentPage = 1,
    this.hasMoreData = true,
    this.searchQuery = '',
    this.useStaticData = false,
  });

  OrderHistoryState copyWith({
    bool? isLoading,
    List<OrderHistoryEntity>? orders,
    OrderHistorySummaryEntity? summary,
    String? error,
    String? selectedStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? currentPage,
    bool? hasMoreData,
    String? searchQuery,
    bool? useStaticData,
  }) {
    return OrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      summary: summary ?? this.summary,
      error: error ?? this.error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      searchQuery: searchQuery ?? this.searchQuery,
      useStaticData: useStaticData ?? this.useStaticData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistoryState &&
        other.isLoading == isLoading &&
        other.orders == orders &&
        other.summary == summary &&
        other.error == error &&
        other.selectedStatus == selectedStatus &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.currentPage == currentPage &&
        other.hasMoreData == hasMoreData &&
        other.searchQuery == searchQuery &&
        other.useStaticData == useStaticData;
  }

  @override
  int get hashCode => 
      isLoading.hashCode ^
      orders.hashCode ^
      summary.hashCode ^
      error.hashCode ^
      selectedStatus.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode ^
      currentPage.hashCode ^
      hasMoreData.hashCode ^
      searchQuery.hashCode ^
      useStaticData.hashCode;

  @override
  String toString() {
    return 'OrderHistoryState(isLoading: $isLoading, orders: ${orders.length}, error: $error)';
  }
}

// Order History Notifier
class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  final OrderHistoryRepository _repository;
  final Ref _ref;

  OrderHistoryNotifier(this._repository, this._ref) : super(const OrderHistoryState());

  int get _outletId => _ref.read(outletIdProvider);

  /// Load order history
  Future<void> loadOrderHistory({
    bool refresh = false,
    int page = 1,
  }) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, currentPage: 1);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _repository.getOrderHistoryPaginated(
        outletId: _outletId,
        page: page,
        limit: 20,
        status: state.selectedStatus,
        fromDate: state.fromDate != null ? _formatDate(state.fromDate!) : null,
        toDate: state.toDate != null ? _formatDate(state.toDate!) : null,
      );

      result.when(
        success: (orders, _) {
          final newOrders = refresh ? orders.map((order) => OrderHistoryEntity.fromModel(order)).toList() : [...state.orders, ...orders.map((order) => OrderHistoryEntity.fromModel(order)).toList()];
          state = state.copyWith(
            isLoading: false,
            orders: newOrders,
            currentPage: page,
            hasMoreData: orders.length >= 20,
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          debugPrint('API Error: $error. Falling back to static data.');
          // Fallback to static data on API error
          final staticOrders = StaticOrderHistoryData.getSampleOrders();
          final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
          state = state.copyWith(
            isLoading: false,
            orders: filteredStaticOrders,
            error: null,
            useStaticData: true,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception: $e. Falling back to static data.');
      // Fallback to static data on exception
      final staticOrders = StaticOrderHistoryData.getSampleOrders();
      final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
      state = state.copyWith(
        isLoading: false,
        orders: filteredStaticOrders,
        error: null,
        useStaticData: true,
      );
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (state.isLoading || !state.hasMoreData) return;

    final nextPage = state.currentPage + 1;
    await loadOrderHistory(page: nextPage);
  }

  /// Refresh order history
  Future<void> refreshOrderHistory() async {
    await loadOrderHistory(refresh: true);
  }

  /// Load order history summary
  Future<void> loadOrderHistorySummary() async {
    try {
      final result = await _repository.getOrderHistorySummary(_outletId);

      result.when(
        success: (summary, _) {
          state = state.copyWith(summary: OrderHistorySummaryEntity.fromModel(summary), useStaticData: false);
        },
        failure: (error, _, __) {
          debugPrint('API Error loading summary: $error. Falling back to static data.');
          // Fallback to static data on API error
          state = state.copyWith(summary: StaticOrderHistoryData.getSampleSummary(), useStaticData: true);
        },
      );
    } catch (e) {
      debugPrint('Exception loading summary: $e. Falling back to static data.');
      // Fallback to static data on exception
      state = state.copyWith(summary: StaticOrderHistoryData.getSampleSummary(), useStaticData: true);
    }
  }

  /// Apply current filters to static data
  List<OrderHistoryEntity> _applyFiltersToStaticData(List<OrderHistoryEntity> staticOrders) {
    var filteredOrders = staticOrders;

    // Filter by status
    if (state.selectedStatus != null) {
      filteredOrders = filteredOrders.where((order) => 
          order.status.toLowerCase() == state.selectedStatus!.toLowerCase()
      ).toList();
    }

    // Filter by date range
    if (state.fromDate != null && state.toDate != null) {
      filteredOrders = filteredOrders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.isAfter(state.fromDate!.subtract(const Duration(days: 1))) &&
               orderDate.isBefore(state.toDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filteredOrders = filteredOrders.where((order) =>
          order.orderNumber?.toLowerCase().contains(query) == true ||
          order.tableName?.toLowerCase().contains(query) == true ||
          order.customerName?.toLowerCase().contains(query) == true ||
          order.captainName?.toLowerCase().contains(query) == true
      ).toList();
    }

    return filteredOrders;
  }

  /// Filter by status
  void filterByStatus(String? status) {
    state = state.copyWith(selectedStatus: status, currentPage: 1);
    loadOrderHistory();
  }

  /// Filter by date range
  void filterByDateRange(DateTime? fromDate, DateTime? toDate) {
    state = state.copyWith(
      fromDate: fromDate,
      toDate: toDate,
      currentPage: 1,
    );
    loadOrderHistory();
  }

  /// Search orders
  Future<void> searchOrders(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchQuery: '', currentPage: 1);
      loadOrderHistory();
      return;
    }

    state = state.copyWith(isLoading: true, searchQuery: query, currentPage: 1);

    try {
      final result = await _repository.searchOrders(
        outletId: _outletId,
        query: query,
        page: 1,
      );

      result.when(
        success: (orders, _) {
          state = state.copyWith(
            isLoading: false,
            orders: orders.map((order) => OrderHistoryEntity.fromModel(order)).toList(),
            hasMoreData: orders.length >= 20,
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          debugPrint('API Error searching orders: $error. Falling back to static data.');
          // Fallback to static data on API error
          final staticOrders = StaticOrderHistoryData.getSampleOrders();
          final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
          state = state.copyWith(
            isLoading: false,
            orders: filteredStaticOrders,
            error: null,
            useStaticData: true,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception searching orders: $e. Falling back to static data.');
      // Fallback to static data on exception
      final staticOrders = StaticOrderHistoryData.getSampleOrders();
      final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
      state = state.copyWith(
        isLoading: false,
        orders: filteredStaticOrders,
        error: null,
        useStaticData: true,
      );
    }
  }

  /// Clear filters
  void clearFilters() {
    state = state.copyWith(
      selectedStatus: null,
      fromDate: null,
      toDate: null,
      searchQuery: '',
      currentPage: 1,
    );
    loadOrderHistory();
  }

  /// Get today's orders
  Future<void> loadTodayOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getTodayOrders(_outletId);

      result.when(
        success: (orders, _) {
          state = state.copyWith(
            isLoading: false,
            orders: orders.map((order) => OrderHistoryEntity.fromModel(order)).toList(),
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          debugPrint('API Error loading today orders: $error. Falling back to static data.');
          // Fallback to static data on API error
          final staticOrders = StaticOrderHistoryData.getSampleOrders();
          final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
          state = state.copyWith(
            isLoading: false,
            orders: filteredStaticOrders,
            error: null,
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
            useStaticData: true,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception loading today orders: $e. Falling back to static data.');
      // Fallback to static data on exception
      final staticOrders = StaticOrderHistoryData.getSampleOrders();
      final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
      state = state.copyWith(
        isLoading: false,
        orders: filteredStaticOrders,
        error: null,
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
        useStaticData: true,
      );
    }
  }

  /// Get this week's orders
  Future<void> loadThisWeekOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getThisWeekOrders(_outletId);

      result.when(
        success: (orders, _) {
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          state = state.copyWith(
            isLoading: false,
            orders: orders.map((order) => OrderHistoryEntity.fromModel(order)).toList(),
            fromDate: weekStart,
            toDate: now,
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          debugPrint('API Error loading week orders: $error. Falling back to static data.');
          // Fallback to static data on API error
          final staticOrders = StaticOrderHistoryData.getSampleOrders();
          final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          state = state.copyWith(
            isLoading: false,
            orders: filteredStaticOrders,
            error: null,
            fromDate: weekStart,
            toDate: now,
            useStaticData: true,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception loading week orders: $e. Falling back to static data.');
      // Fallback to static data on exception
      final staticOrders = StaticOrderHistoryData.getSampleOrders();
      final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      state = state.copyWith(
        isLoading: false,
        orders: filteredStaticOrders,
        error: null,
        fromDate: weekStart,
        toDate: now,
        useStaticData: true,
      );
    }
  }

  /// Get this month's orders
  Future<void> loadThisMonthOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getThisMonthOrders(_outletId);

      result.when(
        success: (orders, _) {
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          state = state.copyWith(
            isLoading: false,
            orders: orders.map((order) => OrderHistoryEntity.fromModel(order)).toList(),
            fromDate: monthStart,
            toDate: now,
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          debugPrint('API Error loading month orders: $error. Falling back to static data.');
          // Fallback to static data on API error
          final staticOrders = StaticOrderHistoryData.getSampleOrders();
          final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          state = state.copyWith(
            isLoading: false,
            orders: filteredStaticOrders,
            error: null,
            fromDate: monthStart,
            toDate: now,
            useStaticData: true,
          );
        },
      );
    } catch (e) {
      debugPrint('Exception loading month orders: $e. Falling back to static data.');
      // Fallback to static data on exception
      final staticOrders = StaticOrderHistoryData.getSampleOrders();
      final filteredStaticOrders = _applyFiltersToStaticData(staticOrders);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      state = state.copyWith(
        isLoading: false,
        orders: filteredStaticOrders,
        error: null,
        fromDate: monthStart,
        toDate: now,
        useStaticData: true,
      );
    }
  }

  /// Format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Providers
final orderHistoryProvider = StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  final repository = ref.watch(orderHistoryRepositoryProvider);
  return OrderHistoryNotifier(repository, ref);
});

// Async provider for order history state
final orderHistoryAsyncProvider = Provider<AsyncValue<OrderHistoryState>>((ref) {
  final orderHistoryState = ref.watch(orderHistoryProvider);
  
  if (orderHistoryState.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (orderHistoryState.error != null) {
    return AsyncValue.error(orderHistoryState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(orderHistoryState);
});

// Provider for orders list
final ordersProvider = Provider<List<OrderHistoryEntity>>((ref) {
  return ref.watch(orderHistoryProvider).orders;
});

// Provider for filtered orders
final filteredOrdersProvider = Provider<List<OrderHistoryEntity>>((ref) {
  final state = ref.watch(orderHistoryProvider);
  var orders = state.orders;

  // Filter by status
  if (state.selectedStatus != null) {
    orders = orders.where((order) => 
        order.status.toLowerCase() == state.selectedStatus!.toLowerCase()
    ).toList();
  }

  // Filter by date range
  if (state.fromDate != null && state.toDate != null) {
    orders = orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.isAfter(state.fromDate!.subtract(const Duration(days: 1))) &&
             orderDate.isBefore(state.toDate!.add(const Duration(days: 1)));
    }).toList();
  }

  // Filter by search query
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    orders = orders.where((order) =>
        order.orderNumber?.toLowerCase().contains(query) == true ||
        order.tableName?.toLowerCase().contains(query) == true ||
        order.customerName?.toLowerCase().contains(query) == true ||
        order.captainName?.toLowerCase().contains(query) == true
    ).toList();
  }

  return orders;
});

// Provider for order summary
final orderHistorySummaryProvider = Provider<OrderHistorySummaryEntity?>((ref) {
  return ref.watch(orderHistoryProvider).summary;
});

// Provider for loading state
final isOrderHistoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(orderHistoryProvider).isLoading;
});

// Provider for error state
final orderHistoryErrorProvider = Provider<String?>((ref) {
  return ref.watch(orderHistoryProvider).error;
});

// Provider for static data indicator
final isUsingStaticDataProvider = Provider<bool>((ref) {
  return ref.watch(orderHistoryProvider).useStaticData;
});
