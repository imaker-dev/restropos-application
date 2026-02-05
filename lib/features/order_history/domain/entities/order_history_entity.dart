import '../../data/models/order_history_models.dart';

/// Domain entity for Order History
/// This represents clean business object used throughout app
class OrderHistoryEntity {
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
  final List<OrderHistoryItemEntity> items;
  final String? duration;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const OrderHistoryEntity({
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

  /// Create from API model
  factory OrderHistoryEntity.fromModel(OrderHistory model) {
    return OrderHistoryEntity(
      id: model.id,
      uuid: model.uuid,
      orderNumber: model.orderNumber,
      tableId: model.tableId,
      tableNumber: model.tableNumber,
      tableName: model.tableName,
      outletId: model.outletId,
      orderType: model.orderType,
      status: model.status,
      covers: model.covers,
      customerName: model.customerName,
      customerPhone: model.customerPhone,
      captainId: model.captainId,
      captainName: model.captainName,
      createdBy: model.createdBy,
      subtotal: model.subtotal,
      taxAmount: model.taxAmount,
      discountAmount: model.discountAmount,
      serviceCharge: model.serviceCharge,
      total: model.total,
      paidAmount: model.paidAmount,
      balanceAmount: model.balanceAmount,
      notes: model.notes,
      items: model.items.map((item) => OrderHistoryItemEntity.fromModel(item)).toList(),
      duration: model.duration,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      completedAt: model.completedAt,
      cancelledAt: model.cancelledAt,
    );
  }

  /// Convert to API model
  OrderHistory toModel() {
    return OrderHistory(
      id: id,
      uuid: uuid,
      orderNumber: orderNumber,
      tableId: tableId,
      tableNumber: tableNumber,
      tableName: tableName,
      outletId: outletId,
      orderType: orderType,
      status: status,
      covers: covers,
      customerName: customerName,
      customerPhone: customerPhone,
      captainId: captainId,
      captainName: captainName,
      createdBy: createdBy,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      serviceCharge: serviceCharge,
      total: total,
      paidAmount: paidAmount,
      balanceAmount: balanceAmount,
      notes: notes,
      items: items.map((item) => item.toModel()).toList(),
      duration: duration,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
    );
  }

  /// Get display order number
  String get displayOrderNumber => orderNumber ?? '#$id';

  /// Get display table name
  String get displayTable => tableName ?? tableNumber ?? 'Table $tableId';

  /// Get display customer name
  String get displayCustomer => customerName ?? 'Walk-in';

  /// Check if order is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if order is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Check if order is refunded
  bool get isRefunded => status.toLowerCase() == 'refunded';

  /// Check if order is fully paid
  bool get isPaid => (paidAmount ?? 0.0) >= total;

  /// Get display status
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

  /// Get status color
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return '#10B981'; // Green
      case 'cancelled':
        return '#EF4444'; // Red
      case 'refunded':
        return '#F59E0B'; // Amber
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration == null || duration!.isEmpty) return 'N/A';
    return duration!;
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  OrderHistoryEntity copyWith({
    int? id,
    String? uuid,
    String? orderNumber,
    int? tableId,
    String? tableNumber,
    String? tableName,
    int? outletId,
    String? orderType,
    String? status,
    int? covers,
    String? customerName,
    String? customerPhone,
    int? captainId,
    String? captainName,
    String? createdBy,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? serviceCharge,
    double? total,
    double? paidAmount,
    double? balanceAmount,
    String? notes,
    List<OrderHistoryItemEntity>? items,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return OrderHistoryEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      orderNumber: orderNumber ?? this.orderNumber,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      tableName: tableName ?? this.tableName,
      outletId: outletId ?? this.outletId,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      covers: covers ?? this.covers,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      createdBy: createdBy ?? this.createdBy,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistoryEntity &&
        other.id == id &&
        other.uuid == uuid;
  }

  @override
  int get hashCode {
    return id.hashCode ^ uuid.hashCode;
  }

  @override
  String toString() {
    return 'OrderHistoryEntity(id: $id, orderNumber: $orderNumber, status: $status)';
  }
}

/// Domain entity for Order History Item
class OrderHistoryItemEntity {
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

  const OrderHistoryItemEntity({
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

  /// Create from API model
  factory OrderHistoryItemEntity.fromModel(OrderHistoryItem model) {
    return OrderHistoryItemEntity(
      id: model.id,
      orderId: model.orderId,
      itemId: model.itemId,
      itemName: model.itemName,
      itemShortCode: model.itemShortCode,
      price: model.price,
      quantity: model.quantity,
      subtotal: model.subtotal,
      variantName: model.variantName,
      notes: model.notes,
      status: model.status,
    );
  }

  /// Convert to API model
  OrderHistoryItem toModel() {
    return OrderHistoryItem(
      id: id,
      orderId: orderId,
      itemId: itemId,
      itemName: itemName,
      itemShortCode: itemShortCode,
      price: price,
      quantity: quantity,
      subtotal: subtotal,
      variantName: variantName,
      notes: notes,
      status: status,
    );
  }

  /// Get display name with variant
  String get displayName {
    if (variantName != null && variantName!.isNotEmpty) {
      return '$itemName ($variantName)';
    }
    return itemName;
  }

  /// Get display status
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

  /// Get formatted price
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  /// Get formatted subtotal
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';

  OrderHistoryItemEntity copyWith({
    int? id,
    int? orderId,
    int? itemId,
    String? itemName,
    String? itemShortCode,
    double? price,
    int? quantity,
    double? subtotal,
    String? variantName,
    String? notes,
    String? status,
  }) {
    return OrderHistoryItemEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemShortCode: itemShortCode ?? this.itemShortCode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      variantName: variantName ?? this.variantName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistoryItemEntity &&
        other.id == id &&
        other.orderId == orderId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ orderId.hashCode;
  }

  @override
  String toString() {
    return 'OrderHistoryItemEntity(id: $id, itemName: $itemName, quantity: $quantity)';
  }
}

/// Domain entity for Order History Summary
class OrderHistorySummaryEntity {
  final int totalOrders;
  final double totalRevenue;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final DateTime fromDate;
  final DateTime toDate;

  const OrderHistorySummaryEntity({
    required this.totalOrders,
    required this.totalRevenue,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.fromDate,
    required this.toDate,
  });

  /// Create from API model
  factory OrderHistorySummaryEntity.fromModel(OrderHistorySummary model) {
    return OrderHistorySummaryEntity(
      totalOrders: model.totalOrders,
      totalRevenue: model.totalRevenue,
      completedOrders: model.completedOrders,
      cancelledOrders: model.cancelledOrders,
      averageOrderValue: model.averageOrderValue,
      fromDate: model.fromDate,
      toDate: model.toDate,
    );
  }

  /// Convert to API model
  OrderHistorySummary toModel() {
    return OrderHistorySummary(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      averageOrderValue: averageOrderValue,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// Get completion rate
  double get completionRate {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }

  /// Get formatted revenue
  String get formattedRevenue => '₹${totalRevenue.toStringAsFixed(2)}';

  /// Get formatted average order value
  String get formattedAverageOrderValue => '₹${averageOrderValue.toStringAsFixed(2)}';

  /// Get formatted date range
  String get formattedDateRange {
    return '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}';
  }

  OrderHistorySummaryEntity copyWith({
    int? totalOrders,
    double? totalRevenue,
    int? completedOrders,
    int? cancelledOrders,
    double? averageOrderValue,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return OrderHistorySummaryEntity(
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      completedOrders: completedOrders ?? this.completedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderHistorySummaryEntity &&
        other.fromDate == fromDate &&
        other.toDate == toDate;
  }

  @override
  int get hashCode {
    return fromDate.hashCode ^ toDate.hashCode;
  }

  @override
  String toString() {
    return 'OrderHistorySummaryEntity(totalOrders: $totalOrders, revenue: $totalRevenue)';
  }
}
