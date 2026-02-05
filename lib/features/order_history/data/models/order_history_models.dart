/// API Models for Order History Module

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

    // Parse dates
    DateTime? completedAt;
    if (json['completedAt'] != null) {
      completedAt = DateTime.parse(json['completedAt'].toString());
    }

    DateTime? cancelledAt;
    if (json['cancelledAt'] != null) {
      cancelledAt = DateTime.parse(json['cancelledAt'].toString());
    }

    return OrderHistory(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String?,
      orderNumber: json['orderNumber'] as String?,
      tableId: json['tableId'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String?,
      tableName: json['tableName'] as String?,
      outletId: json['outletId'] as int? ?? 0,
      orderType: json['orderType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      covers: json['covers'] as int? ?? 0,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      captainId: json['captainId'] as int?,
      captainName: json['captainName'] as String?,
      createdBy: json['createdBy'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      items: items,
      duration: json['duration'] as String?,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString()) 
          : null,
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
    return OrderHistoryItem(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      itemId: json['itemId'] as int? ?? 0,
      itemName: json['itemName'] as String? ?? '',
      itemShortCode: json['itemShortCode'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      variantName: json['variantName'] as String?,
      notes: json['notes'] as String?,
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
