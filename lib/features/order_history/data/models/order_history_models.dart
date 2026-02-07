/// API Models for Order History Module

DateTime _parseApiDate(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  final raw = value.toString();
  if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  try {
    return DateTime.parse(raw);
  } catch (_) {
    try {
      return DateTime.parse(raw.replaceFirst(' ', 'T'));
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

double _parseApiDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _parseApiInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class OrderHistoryPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const OrderHistoryPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory OrderHistoryPagination.fromJson(Map<String, dynamic> json) {
    return OrderHistoryPagination(
      page: _parseApiInt(json['page']),
      limit: _parseApiInt(json['limit']),
      total: _parseApiInt(json['total']),
      totalPages: _parseApiInt(json['totalPages']),
    );
  }
}

class OrderHistoryPage {
  final List<OrderHistory> orders;
  final OrderHistoryPagination pagination;

  const OrderHistoryPage({
    required this.orders,
    required this.pagination,
  });

  factory OrderHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List?;
    final orders =
        rawOrders
            ?.map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <OrderHistory>[];

    final paginationJson = json['pagination'] as Map<String, dynamic>? ?? const {};
    final pagination = OrderHistoryPagination.fromJson(paginationJson);

    return OrderHistoryPage(
      orders: orders,
      pagination: pagination,
    );
  }
}

class OrderHistory {
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
  final int? itemCount;
  final List<OrderHistoryItem> items;
  final String? duration;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const OrderHistory({
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
    this.itemCount,
    required this.items,
    this.duration,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    // Parse items
    final List<OrderHistoryItem> items = [];
    if (json['items'] != null) {
      final itemsList = json['items'] as List;
      for (final item in itemsList) {
        items.add(OrderHistoryItem.fromJson(item as Map<String, dynamic>));
      }
    }

    // Parse dates (supports both camelCase and snake_case)
    final completedAtRaw = json['completedAt'] ?? json['completed_at'];
    final cancelledAtRaw = json['cancelledAt'] ?? json['cancelled_at'];
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    final createdAtRaw = json['createdAt'] ?? json['created_at'];

    final DateTime? completedAt =
        completedAtRaw == null ? null : _parseApiDate(completedAtRaw);
    final DateTime? cancelledAt =
        cancelledAtRaw == null ? null : _parseApiDate(cancelledAtRaw);
    final DateTime? updatedAt =
        updatedAtRaw == null ? null : _parseApiDate(updatedAtRaw);

    return OrderHistory(
      id: _parseApiInt(json['id']),
      uuid: json['uuid'] as String?,
      orderNumber: (json['orderNumber'] ?? json['order_number']) as String?,
      tableId: _parseApiInt(json['tableId'] ?? json['table_id']),
      tableNumber: (json['tableNumber'] ?? json['table_number']) as String?,
      tableName: (json['tableName'] ?? json['table_name']) as String?,
      outletId: _parseApiInt(json['outletId'] ?? json['outlet_id']),
      orderType: (json['orderType'] ?? json['order_type']) as String? ?? '',
      status: json['status'] as String? ?? '',
      covers: _parseApiInt(json['covers'] ?? json['guest_count']),
      customerName: (json['customerName'] ?? json['customer_name']) as String?,
      customerPhone: (json['customerPhone'] ?? json['customer_phone']) as String?,
      captainId: (json['captainId'] ?? json['created_by']) as int?,
      captainName:
          (json['captainName'] ?? json['created_by_name']) as String?,
      createdBy: (json['createdBy'] ?? json['created_by_name']) as String?,
      subtotal: _parseApiDouble(json['subtotal'] ?? json['subtotal_amount'] ?? json['subtotal']),
      taxAmount: _parseApiDouble(json['taxAmount'] ?? json['tax_amount']),
      discountAmount:
          _parseApiDouble(json['discountAmount'] ?? json['discount_amount']),
      serviceCharge: _parseApiDouble(json['serviceCharge'] ?? json['service_charge']),
      total: _parseApiDouble(json['total'] ?? json['total_amount']),
      paidAmount: json['paidAmount'] != null
          ? _parseApiDouble(json['paidAmount'])
          : (json['paid_amount'] != null ? _parseApiDouble(json['paid_amount']) : null),
      balanceAmount: json['balanceAmount'] != null
          ? _parseApiDouble(json['balanceAmount'])
          : (json['due_amount'] != null ? _parseApiDouble(json['due_amount']) : null),
      notes: (json['notes'] ?? json['internal_notes']) as String?,
      itemCount: json['itemCount'] != null
          ? _parseApiInt(json['itemCount'])
          : (json['item_count'] != null ? _parseApiInt(json['item_count']) : null),
      items: items,
      duration: json['duration'] as String?,
      createdAt: _parseApiDate(createdAtRaw),
      updatedAt: updatedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'tableName': tableName,
      'outletId': outletId,
      'orderType': orderType,
      'status': status,
      'covers': covers,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'captainId': captainId,
      'captainName': captainName,
      'createdBy': createdBy,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'serviceCharge': serviceCharge,
      'total': total,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'notes': notes,
      'itemCount': itemCount,
      'items': items.map((item) => item.toJson()).toList(),
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isPaid => (paidAmount ?? 0.0) >= total;
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class OrderHistoryItem {
  final int id;
  final int orderId;
  final int itemId;
  final String itemName;
  final String? itemShortCode;
  final double price;
  final int quantity;
  final double subtotal;
  final String? variantName;
  final String? notes;
  final String status;

  const OrderHistoryItem({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.itemName,
    this.itemShortCode,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.variantName,
    this.notes,
    required this.status,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['quantity'];
    final qty = qtyRaw is num
        ? qtyRaw.toInt()
        : (double.tryParse(qtyRaw?.toString() ?? '')?.round() ??
            int.tryParse(qtyRaw?.toString() ?? '') ??
            0);

    final priceRaw = json['price'] ?? json['unit_price'];
    final subtotalRaw = json['subtotal'] ?? json['total_price'];

    return OrderHistoryItem(
      id: _parseApiInt(json['id']),
      orderId: _parseApiInt(json['orderId'] ?? json['order_id']),
      itemId: _parseApiInt(json['itemId'] ?? json['item_id']),
      itemName: (json['itemName'] ?? json['item_name']) as String? ?? '',
      itemShortCode: (json['itemShortCode'] ?? json['short_name']) as String?,
      price: _parseApiDouble(priceRaw),
      quantity: qty,
      subtotal: _parseApiDouble(subtotalRaw),
      variantName: (json['variantName'] ?? json['variant_name']) as String?,
      notes: (json['notes'] ?? json['special_instructions']) as String?,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'itemId': itemId,
      'itemName': itemName,
      'itemShortCode': itemShortCode,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'variantName': variantName,
      'notes': notes,
      'status': status,
    };
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'served':
        return 'Served';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class OrderHistorySummary {
  final int totalOrders;
  final double totalRevenue;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final DateTime fromDate;
  final DateTime toDate;

  const OrderHistorySummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.fromDate,
    required this.toDate,
  });

  factory OrderHistorySummary.fromJson(Map<String, dynamic> json) {
    return OrderHistorySummary(
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      fromDate: DateTime.parse(json['fromDate'].toString()),
      toDate: DateTime.parse(json['toDate'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'averageOrderValue': averageOrderValue,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
    };
  }
}
