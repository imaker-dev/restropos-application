/// API Models for Orders, KOT, Billing, and Payments

class ApiOrder {
  final int id;
  final String? uuid;
  final String? orderNumber;
  final int tableId;
  final String? tableNumber;
  final String? tableName;
  final int outletId;
  final String orderType;
  final String status;
  final int covers;
  final String? customerName;
  final String? customerPhone;
  final int? captainId;
  final String? captainName;
  final String? createdBy;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double serviceCharge;
  final double total;
  final double? paidAmount;
  final double? balanceAmount;
  final String? notes;
  final List<ApiOrderItem> items;
  final List<ApiKotSummary>? kots;
  final List<OrderTimeline>? timeline;
  final String? duration;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ApiOrder({
    required this.id,
    this.uuid,
    this.orderNumber,
    required this.tableId,
    this.tableNumber,
    this.tableName,
    required this.outletId,
    required this.orderType,
    required this.status,
    required this.covers,
    this.customerName,
    this.customerPhone,
    this.captainId,
    this.captainName,
    this.createdBy,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.serviceCharge,
    required this.total,
    this.paidAmount,
    this.balanceAmount,
    this.notes,
    this.items = const [],
    this.kots,
    this.timeline,
    this.duration,
    required this.createdAt,
    this.updatedAt,
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    return ApiOrder(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String?,
      orderNumber: json['orderNumber'] as String?,
      tableId: json['tableId'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String?,
      tableName: json['tableName'] as String?,
      outletId: json['outletId'] as int? ?? 0,
      orderType: json['orderType'] as String? ?? 'dine_in',
      status: json['status'] as String? ?? 'pending',
      covers: json['covers'] as int? ?? json['guestCount'] as int? ?? 1,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      captainId: json['captainId'] as int?,
      captainName: json['captainName'] as String?,
      createdBy: json['createdBy'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      total:
          (json['total'] as num?)?.toDouble() ??
          (json['grandTotal'] as num?)?.toDouble() ??
          0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      items:
          (json['items'] as List?)
              ?.map((e) => ApiOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      kots: (json['kots'] as List?)
          ?.map((e) => ApiKotSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List?)
          ?.map((e) => OrderTimeline.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'tableId': tableId,
    'tableNumber': tableNumber,
    'outletId': outletId,
    'orderType': orderType,
    'status': status,
    'covers': covers,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'total': total,
    'notes': notes,
    'items': items.map((e) => e.toJson()).toList(),
  };

  // Backwards compatibility
  int get guestCount => covers;
  double get grandTotal => total;

  bool get isActive => status == 'active' || status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isBilled => status == 'billed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  int get pendingItemsCount => items.where((i) => i.isPending).length;
  int get kotSentItemsCount => items.where((i) => i.isKotSent).length;
  int get kotPendingCount =>
      kots?.where((k) => k.status == 'pending').length ?? 0;
  int get kotPreparingCount =>
      kots?.where((k) => k.status == 'preparing').length ?? 0;
  int get kotReadyCount => kots?.where((k) => k.status == 'ready').length ?? 0;
}

class ApiKotSummary {
  final int id;
  final String kotNumber;
  final String status;
  final String? station;
  final int itemCount;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;

  const ApiKotSummary({
    required this.id,
    required this.kotNumber,
    required this.status,
    this.station,
    required this.itemCount,
    this.sentAt,
    this.acceptedAt,
    this.readyAt,
  });

  factory ApiKotSummary.fromJson(Map<String, dynamic> json) {
    return ApiKotSummary(
      id: json['id'] as int? ?? 0,
      kotNumber: json['kotNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      station: json['station'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'] as String)
          : null,
    );
  }
}

class OrderTimeline {
  final String action;
  final String time;
  final String? by;

  const OrderTimeline({required this.action, required this.time, this.by});

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      action: json['action'] as String? ?? '',
      time: json['time'] as String? ?? '',
      by: json['by'] as String?,
    );
  }
}

class ApiOrderItem {
  final int id;
  final int? orderId;
  final int itemId;
  final String name;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double? addonTotal;
  final double lineTotal;
  final int? variantId;
  final List<OrderItemAddon>? addons;
  final String? specialInstructions;
  final String? notes;
  final String status;
  final String? kotStatus;
  final int? kotId;
  final String? kotNumber;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const ApiOrderItem({
    required this.id,
    this.orderId,
    required this.itemId,
    required this.name,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    this.addonTotal,
    required this.lineTotal,
    this.variantId,
    this.addons,
    this.specialInstructions,
    this.notes,
    required this.status,
    this.kotStatus,
    this.kotId,
    this.kotNumber,
    this.createdAt,
    this.cancelledAt,
    this.cancelReason,
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    return ApiOrderItem(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int?,
      itemId: json['itemId'] as int? ?? 0,
      name: json['name'] as String? ?? json['itemName'] as String? ?? '',
      variantName: json['variantName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      addonTotal: (json['addonTotal'] as num?)?.toDouble(),
      lineTotal:
          (json['lineTotal'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0,
      variantId: json['variantId'] as int?,
      addons: (json['addons'] as List?)
          ?.map((e) => OrderItemAddon.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialInstructions: json['specialInstructions'] as String?,
      notes: json['notes'] as String?,
      status:
          json['status'] as String? ??
          json['kotStatus'] as String? ??
          'pending',
      kotStatus: json['kotStatus'] as String?,
      kotId: json['kotId'] as int?,
      kotNumber: json['kotNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
      cancelReason: json['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'itemId': itemId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'lineTotal': lineTotal,
    'variantId': variantId,
    'variantName': variantName,
    'notes': notes,
    'status': status,
    'kotId': kotId,
  };

  // Backwards compatibility
  String get itemName => name;
  double get totalPrice => lineTotal;

  bool get isPending => status == 'pending' || kotStatus == 'pending';
  bool get isKotSent =>
      status == 'kot_sent' || status == 'preparing' || kotStatus == 'preparing';
  bool get isPreparing => status == 'preparing' || kotStatus == 'preparing';
  bool get isReady => status == 'ready' || kotStatus == 'ready';
  bool get isServed => status == 'served' || kotStatus == 'served';
  bool get isCancelled => status == 'cancelled';
}

class OrderItemAddon {
  final int id;
  final String name;
  final double price;

  const OrderItemAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) {
    return OrderItemAddon(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

class CreateOrderRequest {
  final int tableId;
  final int outletId;
  final int covers;
  final String orderType;
  final List<CreateOrderItemRequest> items;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  const CreateOrderRequest({
    required this.tableId,
    required this.outletId,
    required this.covers,
    this.orderType = 'dine_in',
    required this.items,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'tableId': tableId,
    'outletId': outletId,
    'covers': covers,
    'orderType': orderType,
    'items': items.map((e) => e.toJson()).toList(),
    if (customerName != null) 'customerName': customerName,
    if (customerPhone != null) 'customerPhone': customerPhone,
    if (notes != null) 'notes': notes,
  };
}

class CreateOrderItemRequest {
  final int itemId;
  final int quantity;
  final int? variantId;
  final List<int>? addonIds;
  final String? specialInstructions;
  final String? notes;

  const CreateOrderItemRequest({
    required this.itemId,
    required this.quantity,
    this.variantId,
    this.addonIds,
    this.specialInstructions,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'quantity': quantity,
    if (variantId != null) 'variantId': variantId,
    if (addonIds != null && addonIds!.isNotEmpty) 'addonIds': addonIds,
    if (specialInstructions != null) 'specialInstructions': specialInstructions,
    if (notes != null) 'notes': notes,
  };
}

class AddOrderItemsRequest {
  final List<CreateOrderItemRequest> items;

  const AddOrderItemsRequest({required this.items});

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class UpdateQuantityRequest {
  final int quantity;

  const UpdateQuantityRequest({required this.quantity});

  Map<String, dynamic> toJson() => {'quantity': quantity};
}

class CancelItemRequest {
  final String reason;
  final int? cancelReasonId;

  const CancelItemRequest({required this.reason, this.cancelReasonId});

  Map<String, dynamic> toJson() => {
    'reason': reason,
    if (cancelReasonId != null) 'cancelReasonId': cancelReasonId,
  };
}

class CancelOrderRequest {
  final String reason;
  final int? cancelReasonId;

  const CancelOrderRequest({required this.reason, this.cancelReasonId});

  Map<String, dynamic> toJson() => {
    'reason': reason,
    if (cancelReasonId != null) 'cancelReasonId': cancelReasonId,
  };
}

class CancelReason {
  final String code;
  final String label;
  final bool requiresNote;

  const CancelReason({
    required this.code,
    required this.label,
    this.requiresNote = false,
  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    return CancelReason(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      requiresNote: json['requiresNote'] as bool? ?? false,
    );
  }
}

class TransferOrderRequest {
  final int toTableId;
  final String? reason;

  const TransferOrderRequest({required this.toTableId, this.reason});

  Map<String, dynamic> toJson() => {
    'toTableId': toTableId,
    if (reason != null) 'reason': reason,
  };
}

class TransferOrderResponse {
  final int orderId;
  final int fromTableId;
  final int toTableId;
  final String? fromTableNumber;
  final String? toTableNumber;

  const TransferOrderResponse({
    required this.orderId,
    required this.fromTableId,
    required this.toTableId,
    this.fromTableNumber,
    this.toTableNumber,
  });

  factory TransferOrderResponse.fromJson(Map<String, dynamic> json) {
    return TransferOrderResponse(
      orderId: json['orderId'] as int? ?? 0,
      fromTableId: json['fromTableId'] as int? ?? 0,
      toTableId: json['toTableId'] as int? ?? 0,
      fromTableNumber: json['fromTableNumber'] as String?,
      toTableNumber: json['toTableNumber'] as String?,
    );
  }
}

// KOT Models
class ApiKot {
  final int id;
  final String kotNumber;
  final int orderId;
  final String? orderNumber;
  final int tableId;
  final String? tableNumber;
  final String? tableName;
  final String status;
  final String? station;
  final String? stationType;
  final List<KotItem> items;
  final int itemCount;
  final int? captainId;
  final String? captainName;
  final String? notes;
  final int? printerId;
  final bool printed;
  final String? waitTime;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final DateTime createdAt;

  const ApiKot({
    required this.id,
    required this.kotNumber,
    required this.orderId,
    this.orderNumber,
    required this.tableId,
    this.tableNumber,
    this.tableName,
    required this.status,
    this.station,
    this.stationType,
    this.items = const [],
    this.itemCount = 0,
    this.captainId,
    this.captainName,
    this.notes,
    this.printerId,
    this.printed = false,
    this.waitTime,
    this.sentAt,
    this.acceptedAt,
    this.readyAt,
    this.servedAt,
    required this.createdAt,
  });

  factory ApiKot.fromJson(Map<String, dynamic> json) {
    return ApiKot(
      id: json['id'] as int? ?? 0,
      kotNumber: json['kotNumber'] as String? ?? '',
      orderId: json['orderId'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String?,
      tableId: json['tableId'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String?,
      tableName: json['tableName'] as String?,
      status: json['status'] as String? ?? 'pending',
      station: json['station'] as String?,
      stationType: json['stationType'] as String?,
      items:
          (json['items'] as List?)
              ?.map((e) => KotItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemCount: json['itemCount'] as int? ?? 0,
      captainId: json['captainId'] as int?,
      captainName: json['captainName'] as String?,
      notes: json['notes'] as String?,
      printerId: json['printerId'] as int?,
      printed: json['printed'] as bool? ?? false,
      waitTime: json['waitTime'] as String?,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'] as String)
          : null,
      servedAt: json['servedAt'] != null
          ? DateTime.tryParse(json['servedAt'] as String)
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isPrinted => status == 'printed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isServed => status == 'served';
  bool get isInProgress => status == 'in_progress' || status == 'preparing';
  bool get isCompleted => status == 'completed' || status == 'served';
}

class KotItem {
  final String name;
  final int quantity;
  final String? instructions;
  final String? status;

  const KotItem({
    required this.name,
    required this.quantity,
    this.instructions,
    this.status,
  });

  factory KotItem.fromJson(Map<String, dynamic> json) {
    return KotItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      instructions: json['instructions'] as String?,
      status: json['status'] as String?,
    );
  }
}

class SendKotRequest {
  final List<int>? itemIds;

  const SendKotRequest({this.itemIds});

  Map<String, dynamic> toJson() => {
    if (itemIds != null && itemIds!.isNotEmpty) 'itemIds': itemIds,
  };
}

class SendKotResponse {
  final List<ApiKot> tickets;
  final KotSummary? summary;

  const SendKotResponse({required this.tickets, this.summary});

  factory SendKotResponse.fromJson(Map<String, dynamic> json) {
    return SendKotResponse(
      tickets:
          (json['tickets'] as List?)
              ?.map((e) => ApiKot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? KotSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class KotSummary {
  final int totalTickets;
  final int kitchenItems;
  final int barItems;

  const KotSummary({
    required this.totalTickets,
    required this.kitchenItems,
    required this.barItems,
  });

  factory KotSummary.fromJson(Map<String, dynamic> json) {
    return KotSummary(
      totalTickets: json['totalTickets'] as int? ?? 0,
      kitchenItems: json['kitchenItems'] as int? ?? 0,
      barItems: json['barItems'] as int? ?? 0,
    );
  }
}

class TableKotStatus {
  final int tableId;
  final String tableNumber;
  final List<ApiKot> kots;
  final TableKotSummary? summary;

  const TableKotStatus({
    required this.tableId,
    required this.tableNumber,
    this.kots = const [],
    this.summary,
  });

  factory TableKotStatus.fromJson(Map<String, dynamic> json) {
    return TableKotStatus(
      tableId: json['tableId'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String? ?? '',
      kots:
          (json['kots'] as List?)
              ?.map((e) => ApiKot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] != null
          ? TableKotSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TableKotSummary {
  final int pending;
  final int preparing;
  final int ready;

  const TableKotSummary({
    required this.pending,
    required this.preparing,
    required this.ready,
  });

  factory TableKotSummary.fromJson(Map<String, dynamic> json) {
    return TableKotSummary(
      pending: json['pending'] as int? ?? 0,
      preparing: json['preparing'] as int? ?? 0,
      ready: json['ready'] as int? ?? 0,
    );
  }
}

// Billing Models
class ApiInvoice {
  final int id;
  final int orderId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double serviceCharge;
  final double grandTotal;
  final double? tipAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final List<InvoiceTaxBreakdown>? taxBreakdown;
  final DateTime createdAt;
  final DateTime? paidAt;

  const ApiInvoice({
    required this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.serviceCharge,
    required this.grandTotal,
    this.tipAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    this.taxBreakdown,
    required this.createdAt,
    this.paidAt,
  });

  factory ApiInvoice.fromJson(Map<String, dynamic> json) {
    return ApiInvoice(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      tipAmount: (json['tipAmount'] as num?)?.toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'unpaid',
      taxBreakdown: (json['taxBreakdown'] as List?)
          ?.map((e) => InvoiceTaxBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPartiallyPaid => status == 'partially_paid';
  bool get isUnpaid => status == 'unpaid';
}

class InvoiceTaxBreakdown {
  final String name;
  final double rate;
  final double amount;

  const InvoiceTaxBreakdown({
    required this.name,
    required this.rate,
    required this.amount,
  });

  factory InvoiceTaxBreakdown.fromJson(Map<String, dynamic> json) {
    return InvoiceTaxBreakdown(
      name: json['name'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// Payment Models
class ApiPayment {
  final int id;
  final int invoiceId;
  final String paymentMode;
  final double amount;
  final double? receivedAmount;
  final double? changeAmount;
  final String? transactionId;
  final String status;
  final DateTime createdAt;

  const ApiPayment({
    required this.id,
    required this.invoiceId,
    required this.paymentMode,
    required this.amount,
    this.receivedAmount,
    this.changeAmount,
    this.transactionId,
    required this.status,
    required this.createdAt,
  });

  factory ApiPayment.fromJson(Map<String, dynamic> json) {
    return ApiPayment(
      id: json['id'] as int? ?? 0,
      invoiceId: json['invoiceId'] as int? ?? 0,
      paymentMode: json['paymentMode'] as String? ?? 'cash',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble(),
      changeAmount: (json['changeAmount'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ProcessPaymentRequest {
  final int invoiceId;
  final String paymentMode;
  final double amount;
  final double? receivedAmount;
  final String? transactionId;

  const ProcessPaymentRequest({
    required this.invoiceId,
    required this.paymentMode,
    required this.amount,
    this.receivedAmount,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
    'invoiceId': invoiceId,
    'paymentMode': paymentMode,
    'amount': amount,
    if (receivedAmount != null) 'receivedAmount': receivedAmount,
    if (transactionId != null) 'transactionId': transactionId,
  };
}

class SplitPaymentRequest {
  final int invoiceId;
  final List<SplitPaymentItem> payments;

  const SplitPaymentRequest({required this.invoiceId, required this.payments});

  Map<String, dynamic> toJson() => {
    'invoiceId': invoiceId,
    'payments': payments.map((e) => e.toJson()).toList(),
  };
}

class SplitPaymentItem {
  final String paymentMode;
  final double amount;

  const SplitPaymentItem({required this.paymentMode, required this.amount});

  Map<String, dynamic> toJson() => {
    'paymentMode': paymentMode,
    'amount': amount,
  };
}

class CashDrawerStatus {
  final double openingBalance;
  final double currentBalance;
  final double cashIn;
  final double cashOut;
  final bool isOpen;
  final DateTime? openedAt;

  const CashDrawerStatus({
    required this.openingBalance,
    required this.currentBalance,
    required this.cashIn,
    required this.cashOut,
    required this.isOpen,
    this.openedAt,
  });

  factory CashDrawerStatus.fromJson(Map<String, dynamic> json) {
    return CashDrawerStatus(
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      cashIn: (json['cashIn'] as num?)?.toDouble() ?? 0,
      cashOut: (json['cashOut'] as num?)?.toDouble() ?? 0,
      isOpen: json['isOpen'] as bool? ?? false,
      openedAt: json['openedAt'] != null
          ? DateTime.tryParse(json['openedAt'] as String)
          : null,
    );
  }
}

// Discount Models
class ApiDiscount {
  final int id;
  final String name;
  final String type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscount;
  final String? code;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validTo;

  const ApiDiscount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.code,
    this.isActive = true,
    this.validFrom,
    this.validTo,
  });

  factory ApiDiscount.fromJson(Map<String, dynamic> json) {
    return ApiDiscount(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      code: json['code'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'] as String)
          : null,
      validTo: json['validTo'] != null
          ? DateTime.tryParse(json['validTo'] as String)
          : null,
    );
  }

  bool get isPercentage => type == 'percentage';
  bool get isFlat => type == 'flat';
}

class ValidateDiscountRequest {
  final String code;
  final double orderTotal;

  const ValidateDiscountRequest({required this.code, required this.orderTotal});

  Map<String, dynamic> toJson() => {'code': code, 'orderTotal': orderTotal};
}

class ValidateDiscountResponse {
  final bool isValid;
  final ApiDiscount? discount;
  final double? applicableAmount;
  final String? message;

  const ValidateDiscountResponse({
    required this.isValid,
    this.discount,
    this.applicableAmount,
    this.message,
  });

  factory ValidateDiscountResponse.fromJson(Map<String, dynamic> json) {
    return ValidateDiscountResponse(
      isValid: json['isValid'] as bool? ?? false,
      discount: json['discount'] != null
          ? ApiDiscount.fromJson(json['discount'] as Map<String, dynamic>)
          : null,
      applicableAmount: (json['applicableAmount'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }
}

class ApplyDiscountRequest {
  final int discountId;
  final String? reason;

  const ApplyDiscountRequest({required this.discountId, this.reason});

  Map<String, dynamic> toJson() => {
    'discountId': discountId,
    if (reason != null) 'reason': reason,
  };
}

class ServiceCharge {
  final int id;
  final String name;
  final String type;
  final double value;
  final bool isApplicable;

  const ServiceCharge({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.isApplicable = true,
  });

  factory ServiceCharge.fromJson(Map<String, dynamic> json) {
    return ServiceCharge(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      isApplicable: json['isApplicable'] as bool? ?? true,
    );
  }
}

// Reports Models
class DashboardData {
  final double todayRevenue;
  final int totalOrders;
  final int activeOrders;
  final int activeTables;
  final int availableTables;
  final double averageOrderValue;
  final List<HourlyRevenue>? hourlyRevenue;

  const DashboardData({
    required this.todayRevenue,
    required this.totalOrders,
    required this.activeOrders,
    required this.activeTables,
    required this.availableTables,
    required this.averageOrderValue,
    this.hourlyRevenue,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      activeTables: json['activeTables'] as int? ?? 0,
      availableTables: json['availableTables'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      hourlyRevenue: (json['hourlyRevenue'] as List?)
          ?.map((e) => HourlyRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HourlyRevenue {
  final int hour;
  final double revenue;
  final int orderCount;

  const HourlyRevenue({
    required this.hour,
    required this.revenue,
    required this.orderCount,
  });

  factory HourlyRevenue.fromJson(Map<String, dynamic> json) {
    return HourlyRevenue(
      hour: json['hour'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
    );
  }
}
