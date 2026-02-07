import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/order_models.dart';

/// Repository for Order operations
class OrderRepository {
  final ApiService _api;

  OrderRepository(this._api);

  /// Get active orders for an outlet
  Future<ApiResult<List<ApiOrder>>> getActiveOrders(int outletId) async {
    return _api.getList(
      ApiEndpoints.activeOrders(outletId),
      parser: ApiOrder.fromJson,
    );
  }

  /// Get orders by table
  Future<ApiResult<List<ApiOrder>>> getOrdersByTable(int tableId) async {
    return _api.getList(
      ApiEndpoints.ordersByTable(tableId),
      parser: ApiOrder.fromJson,
    );
  }

  /// Get order by ID
  Future<ApiResult<ApiOrder>> getOrderById(int orderId) async {
    return _api.get(
      ApiEndpoints.orderById(orderId),
      parser: (json) => ApiOrder.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Create new order (without items - items added separately)
  Future<ApiResult<ApiOrder>> createOrder({
    required int tableId,
    required int outletId,
    required int guestCount,
    int? floorId,
    int? sectionId,
    String orderType = 'dine_in',
    String? customerName,
    String? customerPhone,
    String? specialInstructions,
  }) async {
    final request = CreateOrderRequest(
      tableId: tableId,
      outletId: outletId,
      guestCount: guestCount,
      floorId: floorId,
      sectionId: sectionId,
      orderType: orderType,
      customerName: customerName,
      customerPhone: customerPhone,
      specialInstructions: specialInstructions,
    );
    return _api.post(
      ApiEndpoints.createOrder,
      data: request.toJson(),
      parser: (json) => ApiOrder.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Add items to existing order
  /// Response: { order: {...}, addedItems: [...] }
  Future<ApiResult<ApiOrder>> addOrderItems({
    required int orderId,
    required List<CreateOrderItemRequest> items,
  }) async {
    final request = AddOrderItemsRequest(items: items);
    return _api.post(
      ApiEndpoints.addOrderItems(orderId),
      data: request.toJson(),
      parser: (json) {
        final data = json as Map<String, dynamic>;
        // Response wraps order in 'order' key
        if (data.containsKey('order')) {
          return ApiOrder.fromJson(data['order'] as Map<String, dynamic>);
        }
        return ApiOrder.fromJson(data);
      },
    );
  }

  /// Update item quantity
  Future<ApiResult<ApiOrderItem>> updateItemQuantity({
    required int orderItemId,
    required int quantity,
  }) async {
    final request = UpdateQuantityRequest(quantity: quantity);
    return _api.put(
      ApiEndpoints.updateItemQuantity(orderItemId),
      data: request.toJson(),
      parser: (json) => ApiOrderItem.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Cancel order item
  Future<ApiResult<ApiOrderItem>> cancelItem({
    required int orderItemId,
    required String reason,
    int? cancelReasonId,
  }) async {
    final request = CancelItemRequest(
      reason: reason,
      cancelReasonId: cancelReasonId,
    );
    return _api.post(
      ApiEndpoints.cancelItem(orderItemId),
      data: request.toJson(),
      parser: (json) => ApiOrderItem.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get cancel reasons
  Future<ApiResult<List<CancelReason>>> getCancelReasons(int outletId) async {
    return _api.getList(
      ApiEndpoints.cancelReasons(outletId),
      parser: CancelReason.fromJson,
    );
  }

  /// Transfer order to another table
  Future<ApiResult<ApiOrder>> transferOrder({
    required int orderId,
    required int toTableId,
  }) async {
    final request = TransferOrderRequest(toTableId: toTableId);
    return _api.post(
      ApiEndpoints.transferOrder(orderId),
      data: request.toJson(),
      parser: (json) => ApiOrder.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get running KOTs for a table
  Future<ApiResult<List<ApiKot>>> getTableKots(int tableId) async {
    return _api.getList(
      ApiEndpoints.tableKots(tableId),
      parser: ApiKot.fromJson,
    );
  }
}

/// Repository for KOT operations
class KotRepository {
  final ApiService _api;

  KotRepository(this._api);

  /// Send KOT
  /// Response: { orderId, orderNumber, tableNumber, tickets: [...] }
  Future<ApiResult<SendKotResponse>> sendKot(int orderId) async {
    return _api.post(
      ApiEndpoints.sendKot(orderId),
      parser: (json) => SendKotResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get active KOTs
  Future<ApiResult<List<ApiKot>>> getActiveKots(int outletId) async {
    return _api.getList(
      ApiEndpoints.activeKots(outletId),
      parser: ApiKot.fromJson,
    );
  }

  /// Get KOTs by order
  Future<ApiResult<List<ApiKot>>> getKotsByOrder(int orderId) async {
    return _api.getList(
      ApiEndpoints.kotsByOrder(orderId),
      parser: ApiKot.fromJson,
    );
  }

  /// Get KOT by ID
  Future<ApiResult<ApiKot>> getKotById(int kotId) async {
    return _api.get(
      ApiEndpoints.kotById(kotId),
      parser: (json) => ApiKot.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Reprint KOT
  Future<ApiResult<ApiKot>> reprintKot(int kotId) async {
    return _api.post(
      ApiEndpoints.reprintKot(kotId),
      parser: (json) => ApiKot.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get kitchen dashboard
  Future<ApiResult<List<ApiKot>>> getKitchenDashboard(int outletId) async {
    return _api.getList(
      ApiEndpoints.kitchenDashboard(outletId),
      parser: ApiKot.fromJson,
    );
  }

  /// Get bar dashboard
  Future<ApiResult<List<ApiKot>>> getBarDashboard(int outletId) async {
    return _api.getList(
      ApiEndpoints.barDashboard(outletId),
      parser: ApiKot.fromJson,
    );
  }
}

/// Repository for Billing operations
class BillingRepository {
  final ApiService _api;

  BillingRepository(this._api);

  /// Generate bill
  Future<ApiResult<ApiInvoice>> generateBill(int orderId) async {
    return _api.post(
      ApiEndpoints.generateBill(orderId),
      parser: (json) => ApiInvoice.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get invoice by order
  Future<ApiResult<ApiInvoice>> getInvoiceByOrder(int orderId) async {
    return _api.get(
      ApiEndpoints.invoiceByOrder(orderId),
      parser: (json) => ApiInvoice.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get invoice by ID
  Future<ApiResult<ApiInvoice>> getInvoiceById(int invoiceId) async {
    return _api.get(
      ApiEndpoints.invoiceById(invoiceId),
      parser: (json) => ApiInvoice.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Print duplicate bill
  Future<ApiResult<ApiInvoice>> printDuplicateBill(int invoiceId) async {
    return _api.post(
      ApiEndpoints.duplicateBill(invoiceId),
      parser: (json) => ApiInvoice.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Repository for Payment operations
class PaymentRepository {
  final ApiService _api;

  PaymentRepository(this._api);

  /// Get payments by order
  Future<ApiResult<List<ApiPayment>>> getPaymentsByOrder(int orderId) async {
    return _api.getList(
      ApiEndpoints.paymentsByOrder(orderId),
      parser: ApiPayment.fromJson,
    );
  }

  /// Process payment
  Future<ApiResult<ApiPayment>> processPayment({
    required int invoiceId,
    required String paymentMode,
    required double amount,
    double? receivedAmount,
    String? transactionId,
  }) async {
    final request = ProcessPaymentRequest(
      invoiceId: invoiceId,
      paymentMode: paymentMode,
      amount: amount,
      receivedAmount: receivedAmount,
      transactionId: transactionId,
    );
    return _api.post(
      ApiEndpoints.processPayment,
      data: request.toJson(),
      parser: (json) => ApiPayment.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Split payment
  Future<ApiResult<List<ApiPayment>>> splitPayment({
    required int invoiceId,
    required List<SplitPaymentItem> payments,
  }) async {
    final request = SplitPaymentRequest(
      invoiceId: invoiceId,
      payments: payments,
    );
    return _api.post(
      ApiEndpoints.splitPayment,
      data: request.toJson(),
      parser: (json) {
        final list = json as List;
        return list
            .map((e) => ApiPayment.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Get cash drawer status
  Future<ApiResult<CashDrawerStatus>> getCashDrawerStatus(int outletId) async {
    return _api.get(
      ApiEndpoints.cashDrawerStatus(outletId),
      parser: (json) => CashDrawerStatus.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Repository for Discount operations
class DiscountRepository {
  final ApiService _api;

  DiscountRepository(this._api);

  /// Get available discounts
  Future<ApiResult<List<ApiDiscount>>> getAvailableDiscounts(
    int outletId,
  ) async {
    return _api.getList(
      ApiEndpoints.availableDiscounts(outletId),
      parser: ApiDiscount.fromJson,
    );
  }

  /// Validate discount code
  Future<ApiResult<ValidateDiscountResponse>> validateDiscount({
    required int outletId,
    required String code,
    required double orderTotal,
  }) async {
    final request = ValidateDiscountRequest(code: code, orderTotal: orderTotal);
    return _api.post(
      ApiEndpoints.validateDiscount(outletId),
      data: request.toJson(),
      parser: (json) =>
          ValidateDiscountResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Apply discount to order
  Future<ApiResult<ApiOrder>> applyDiscount({
    required int orderId,
    required int discountId,
    String? reason,
  }) async {
    final request = ApplyDiscountRequest(
      discountId: discountId,
      reason: reason,
    );
    return _api.post(
      ApiEndpoints.applyDiscount(orderId),
      data: request.toJson(),
      parser: (json) => ApiOrder.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get service charges
  Future<ApiResult<List<ServiceCharge>>> getServiceCharges(int outletId) async {
    return _api.getList(
      ApiEndpoints.serviceCharges(outletId),
      parser: ServiceCharge.fromJson,
    );
  }
}

/// Repository for Reports
class ReportsRepository {
  final ApiService _api;

  ReportsRepository(this._api);

  /// Get live dashboard
  Future<ApiResult<DashboardData>> getLiveDashboard(int outletId) async {
    return _api.get(
      ApiEndpoints.liveDashboard(outletId),
      parser: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }
}

// Providers
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return OrderRepository(api);
});

final kotRepositoryProvider = Provider<KotRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return KotRepository(api);
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return BillingRepository(api);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PaymentRepository(api);
});

final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DiscountRepository(api);
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ReportsRepository(api);
});
