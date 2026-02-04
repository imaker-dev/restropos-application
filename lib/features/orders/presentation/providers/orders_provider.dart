import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';

// State classes
class OrdersState {
  final bool isLoading;
  final List<ApiOrder> orders;
  final ApiOrder? currentOrder;
  final String? error;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.currentOrder,
    this.error,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<ApiOrder>? orders,
    ApiOrder? currentOrder,
    String? error,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      error: error,
    );
  }

  List<ApiOrder> get activeOrders => orders.where((o) => o.isActive).toList();
  List<ApiOrder> get pendingOrders => orders.where((o) => o.isPending).toList();
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repository;
  final Ref _ref;

  OrdersNotifier(this._repository, this._ref) : super(const OrdersState());

  int get _outletId => _ref.read(outletIdProvider);

  Future<void> loadActiveOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getActiveOrders(_outletId);

    result.when(
      success: (orders, _) {
        state = state.copyWith(isLoading: false, orders: orders);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> loadOrdersByTable(int tableId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getOrdersByTable(tableId);

    result.when(
      success: (orders, _) {
        state = state.copyWith(
          isLoading: false,
          orders: orders,
          currentOrder: orders.isNotEmpty ? orders.first : null,
        );
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> loadOrderById(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getOrderById(orderId);

    result.when(
      success: (order, _) {
        state = state.copyWith(isLoading: false, currentOrder: order);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<ApiResult<ApiOrder>> createOrder({
    required int tableId,
    required int guestCount,
    required List<CreateOrderItemRequest> items,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createOrder(
      tableId: tableId,
      outletId: _outletId,
      covers: guestCount,
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );

    result.when(
      success: (order, _) {
        state = state.copyWith(
          isLoading: false,
          currentOrder: order,
          orders: [...state.orders, order],
        );
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );

    return result;
  }

  Future<ApiResult<ApiOrder>> addItems({
    required int orderId,
    required List<CreateOrderItemRequest> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.addOrderItems(
      orderId: orderId,
      items: items,
    );

    result.when(
      success: (order, _) {
        state = state.copyWith(isLoading: false, currentOrder: order);
        _updateOrderInList(order);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );

    return result;
  }

  Future<ApiResult<ApiOrderItem>> updateItemQuantity({
    required int orderItemId,
    required int quantity,
  }) async {
    return _repository.updateItemQuantity(
      orderItemId: orderItemId,
      quantity: quantity,
    );
  }

  Future<ApiResult<ApiOrderItem>> cancelItem({
    required int orderItemId,
    required String reason,
    int? cancelReasonId,
  }) async {
    return _repository.cancelItem(
      orderItemId: orderItemId,
      reason: reason,
      cancelReasonId: cancelReasonId,
    );
  }

  Future<ApiResult<ApiOrder>> transferOrder({
    required int orderId,
    required int toTableId,
  }) async {
    final result = await _repository.transferOrder(
      orderId: orderId,
      toTableId: toTableId,
    );

    result.whenOrNull(
      success: (order, _) {
        state = state.copyWith(currentOrder: order);
        _updateOrderInList(order);
      },
    );

    return result;
  }

  void _updateOrderInList(ApiOrder order) {
    final updatedOrders = state.orders.map((o) {
      return o.id == order.id ? order : o;
    }).toList();
    state = state.copyWith(orders: updatedOrders);
  }

  // Update from WebSocket event
  void updateOrder(ApiOrder order) {
    _updateOrderInList(order);
    if (state.currentOrder?.id == order.id) {
      state = state.copyWith(currentOrder: order);
    }
  }

  void setCurrentOrder(ApiOrder? order) {
    state = state.copyWith(currentOrder: order);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// KOT State
class KotState {
  final bool isLoading;
  final List<ApiKot> kots;
  final String? error;

  const KotState({this.isLoading = false, this.kots = const [], this.error});

  KotState copyWith({bool? isLoading, List<ApiKot>? kots, String? error}) {
    return KotState(
      isLoading: isLoading ?? this.isLoading,
      kots: kots ?? this.kots,
      error: error,
    );
  }
}

class KotNotifier extends StateNotifier<KotState> {
  final KotRepository _repository;
  final Ref _ref;

  KotNotifier(this._repository, this._ref) : super(const KotState());

  int get _outletId => _ref.read(outletIdProvider);

  Future<void> loadActiveKots() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getActiveKots(_outletId);

    result.when(
      success: (kots, _) {
        state = state.copyWith(isLoading: false, kots: kots);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<ApiResult<ApiKot>> sendKot(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.sendKot(orderId);

    result.when(
      success: (kot, _) {
        state = state.copyWith(isLoading: false, kots: [...state.kots, kot]);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );

    return result;
  }

  Future<ApiResult<ApiKot>> reprintKot(int kotId) async {
    return _repository.reprintKot(kotId);
  }

  // Update from WebSocket event
  void updateKot(ApiKot kot) {
    final updatedKots = state.kots.map((k) {
      return k.id == kot.id ? kot : k;
    }).toList();
    state = state.copyWith(kots: updatedKots);
  }
}

// Providers
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repository, ref);
});

final kotProvider = StateNotifierProvider<KotNotifier, KotState>((ref) {
  final repository = ref.watch(kotRepositoryProvider);
  return KotNotifier(repository, ref);
});

final orderByIdProvider = Provider.family<ApiOrder?, int>((ref, orderId) {
  final orders = ref.watch(ordersProvider).orders;
  try {
    return orders.firstWhere((o) => o.id == orderId);
  } catch (_) {
    return null;
  }
});

final currentOrderProvider = Provider<ApiOrder?>((ref) {
  return ref.watch(ordersProvider).currentOrder;
});

final cancelReasonsProvider = FutureProvider<List<CancelReason>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final outletId = ref.watch(outletIdProvider);

  final result = await repository.getCancelReasons(outletId);
  return result.when(
    success: (reasons, _) => reasons,
    failure: (_, __, ___) => <CancelReason>[],
  );
});
