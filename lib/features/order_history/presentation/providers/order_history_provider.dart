import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restro/core/network/api_service.dart';
import 'package:restro/features/order_history/data/repositories/order_history_repository.dart';
import 'package:restro/features/order_history/domain/entities/order_history_entity.dart';
import 'package:restro/core/constants/app_colors.dart';


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
  final String sortBy;
  final String sortOrder;
  final bool useStaticData;
  final bool isInitialized;

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
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.useStaticData = false,
    this.isInitialized = false,
  });

  static const _unset = Object();

  OrderHistoryState copyWith({
    bool? isLoading,
    List<OrderHistoryEntity>? orders,
    Object? summary = _unset,
    Object? error = _unset,
    Object? selectedStatus = _unset,
    Object? fromDate = _unset,
    Object? toDate = _unset,
    int? currentPage,
    bool? hasMoreData,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    bool? useStaticData,
    bool? isInitialized,
  }) {
    return OrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      summary:
          summary == _unset ? this.summary : summary as OrderHistorySummaryEntity?,
      error: error == _unset ? this.error : error as String?,
      selectedStatus:
          selectedStatus == _unset ? this.selectedStatus : selectedStatus as String?,
      fromDate: fromDate == _unset ? this.fromDate : fromDate as DateTime?,
      toDate: toDate == _unset ? this.toDate : toDate as DateTime?,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      useStaticData: useStaticData ?? this.useStaticData,
      isInitialized: isInitialized ?? this.isInitialized,
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
        other.useStaticData == useStaticData &&
        other.isInitialized == isInitialized;
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
      sortBy.hashCode ^
      sortOrder.hashCode ^
      useStaticData.hashCode ^
      isInitialized.hashCode;

  @override
  String toString() {
    return 'OrderHistoryState(isLoading: $isLoading, orders: ${orders.length}, error: $error)';
  }
}

// Order History Notifier
class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  final OrderHistoryRepository _repository;
  final Ref _ref;

  int _activeRequestId = 0;

  OrderHistoryNotifier(this._repository, this._ref) : super(const OrderHistoryState());

  int get _outletId => _ref.read(outletIdProvider);

  String? _mapStatusForApi(String? status) {
    if (status == null) return null;
    switch (status.toLowerCase()) {
      case 'running':
        return 'confirmed';
      default:
        return status;
    }
  }

  Future<void> initialize() async {
    if (state.isInitialized) return;
    state = state.copyWith(isInitialized: true);
    await Future.wait([
      loadOrderHistory(refresh: true),
      loadOrderHistorySummary(),
    ]);
  }

  /// Load order history
  Future<void> loadOrderHistory({
    bool refresh = false,
    int page = 1,
  }) async {
    final requestId = ++_activeRequestId;
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        orders: const [],
        hasMoreData: true,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _repository.getOrderHistoryPaginated(
        outletId: _outletId,
        page: page,
        limit: 20,
        status: _mapStatusForApi(state.selectedStatus),
        search: state.searchQuery,
        startDate: state.fromDate != null ? _formatDate(state.fromDate!) : null,
        endDate: state.toDate != null ? _formatDate(state.toDate!) : null,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      result.when(
        success: (pageData, _) {
          if (requestId != _activeRequestId) return;
          final mapped = pageData.orders.map((order) => OrderHistoryEntity.fromModel(order));
          final newOrders = refresh ? mapped.toList() : [...state.orders, ...mapped];
          final sortedOrders = _sortOrders(newOrders);
          state = state.copyWith(
            isLoading: false,
            orders: sortedOrders,
            currentPage: page,
            hasMoreData: pageData.orders.length >= 20,
            useStaticData: false,
          );
        },
        failure: (error, _, __) {
          if (requestId != _activeRequestId) return;
          state = state.copyWith(
            isLoading: false,
            orders: refresh ? [] : state.orders,
            error: error,
            useStaticData: false,
          );
        },
      );
    } catch (e) {
      if (requestId != _activeRequestId) return;
      state = state.copyWith(
        isLoading: false,
        orders: refresh ? [] : state.orders,
        error: e.toString(),
        useStaticData: false,
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
          state = state.copyWith(useStaticData: false);
        },
      );
    } catch (e) {
      state = state.copyWith(useStaticData: false);
    }
  }

  /// Filter by status
  void filterByStatus(String? status) {
    state = state.copyWith(selectedStatus: status, currentPage: 1);
    loadOrderHistory(refresh: true);
  }

  /// Filter by date range
  void filterByDateRange(DateTime? fromDate, DateTime? toDate) {
    state = state.copyWith(
      fromDate: fromDate,
      toDate: toDate,
      currentPage: 1,
    );
    loadOrderHistory(refresh: true);
  }

  /// Search orders
  Future<void> searchOrders(String query) async {
    state = state.copyWith(searchQuery: query.trim(), currentPage: 1);
    await loadOrderHistory(refresh: true);
  }

  void setSorting({required String sortBy, required String sortOrder}) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder, currentPage: 1);
    loadOrderHistory(refresh: true);
  }

  List<OrderHistoryEntity> _sortOrders(List<OrderHistoryEntity> orders) {
    final sorted = [...orders];

    int compareString(String? a, String? b) {
      final aa = (a ?? '').toLowerCase();
      final bb = (b ?? '').toLowerCase();
      return aa.compareTo(bb);
    }

    int compareDouble(double a, double b) => a.compareTo(b);

    switch (state.sortBy) {
      case 'orderNumber':
        sorted.sort((a, b) => compareString(a.orderNumber, b.orderNumber));
        break;
      case 'totalAmount':
        sorted.sort((a, b) => compareDouble(a.total, b.total));
        break;
      case 'createdAt':
      default:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    if (state.sortOrder.toLowerCase() == 'desc') {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  /// Clear filters
  void clearFilters() {
    state = state.copyWith(
      selectedStatus: null,
      fromDate: null,
      toDate: null,
      searchQuery: '',
      sortBy: 'createdAt',
      sortOrder: 'desc',
      currentPage: 1,
      error: null,
    );
    loadOrderHistory(refresh: true);
  }

  /// Get today's orders
  Future<void> loadTodayOrders() async {
    final now = DateTime.now();
    state = state.copyWith(fromDate: now, toDate: now, currentPage: 1);
    await loadOrderHistory(refresh: true);
  }

  /// Get this week's orders
  Future<void> loadThisWeekOrders() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    state = state.copyWith(fromDate: weekStart, toDate: now, currentPage: 1);
    await loadOrderHistory(refresh: true);
  }

  /// Get this month's orders
  Future<void> loadThisMonthOrders() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    state = state.copyWith(fromDate: monthStart, toDate: now, currentPage: 1);
    await loadOrderHistory(refresh: true);
  }

  /// Format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Providers
final orderHistoryProvider = StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  final repository = ref.watch(orderHistoryRepositoryProvider);
  final notifier = OrderHistoryNotifier(repository, ref);
  notifier.initialize();
  return notifier;
});

final orderHistoryScrollControllerProvider = Provider.autoDispose<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

final orderHistorySearchControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

class OrderHistoryBannerUi {
  final String message;
  const OrderHistoryBannerUi({required this.message});
}

final orderHistoryBannerUiProvider = Provider<OrderHistoryBannerUi?>((ref) {
  return null;
});

class OrderHistoryEmptyUi {
  final IconData icon;
  final String title;
  final String subtitle;
  const OrderHistoryEmptyUi({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

final orderHistoryEmptyUiProvider = Provider<OrderHistoryEmptyUi>((ref) {
  final state = ref.watch(orderHistoryProvider);

  if (state.error != null && state.error!.isNotEmpty) {
    return const OrderHistoryEmptyUi(
      icon: Icons.wifi_off_rounded,
      title: 'Unable to load orders',
      subtitle: 'Please try again.',
    );
  }

  return const OrderHistoryEmptyUi(
    icon: Icons.receipt_long_rounded,
    title: 'No Orders Found',
    subtitle: 'Orders will appear here once created',
  );
});

final orderHistoryDetailProvider = FutureProvider.family<OrderHistoryEntity, int>((ref, orderId) async {
  final repository = ref.watch(orderHistoryRepositoryProvider);
  final result = await repository.getCaptainOrderDetail(orderId);
  return result.when(
    success: (order, _) => OrderHistoryEntity.fromModel(order),
    failure: (message, _, __) => throw Exception(message),
  );
});

class OrderStatusUi {
  final String label;
  final Color color;
  const OrderStatusUi({required this.label, required this.color});
}

final orderStatusUiProvider = Provider.family<OrderStatusUi, String>((ref, status) {
  switch (status.toLowerCase()) {
    case 'running':
      return const OrderStatusUi(label: 'Running', color: AppColors.info);
    case 'confirmed':
      return const OrderStatusUi(label: 'Running', color: AppColors.info);
    case 'completed':
      return const OrderStatusUi(label: 'Completed', color: AppColors.completed);
    case 'cancelled':
      return const OrderStatusUi(label: 'Cancelled', color: AppColors.cancelled);
    case 'refunded':
      return const OrderStatusUi(label: 'Refunded', color: AppColors.refunded);
    default:
      return const OrderStatusUi(label: 'Pending', color: AppColors.textHint);
  }
});

final orderItemStatusUiProvider = Provider.family<OrderStatusUi, String>((ref, status) {
  switch (status.toLowerCase()) {
    case 'served':
      return const OrderStatusUi(label: 'Served', color: AppColors.completed);
    case 'preparing':
      return const OrderStatusUi(label: 'Preparing', color: AppColors.warning);
    case 'cancelled':
      return const OrderStatusUi(label: 'Cancelled', color: AppColors.cancelled);
    default:
      return OrderStatusUi(label: status, color: AppColors.textHint);
  }
});

class OrderHistoryDateFormatter {
  const OrderHistoryDateFormatter();

  String format(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

final orderHistoryDateFormatterProvider = Provider<OrderHistoryDateFormatter>((ref) {
  return const OrderHistoryDateFormatter();
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
