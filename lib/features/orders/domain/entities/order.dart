import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum OrderType { dineIn, delivery, pickUp }
enum OrderStatus { active, completed, cancelled }

class Order extends Equatable {
  final String id;
  final String tableId;
  final String tableName;
  final OrderType type;
  final OrderStatus status;
  final List<OrderItem> items;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final int guestCount;
  final String captainId;
  final String captainName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double serviceCharge;
  final double roundOff;
  final double grandTotal;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.tableName,
    this.type = OrderType.dineIn,
    this.status = OrderStatus.active,
    this.items = const [],
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.guestCount = 1,
    required this.captainId,
    required this.captainName,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.serviceCharge = 0,
    this.roundOff = 0,
    this.grandTotal = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty => items.isEmpty;
  bool get isActive => status == OrderStatus.active;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  List<OrderItem> get pendingItems => items.where((i) => i.isPending).toList();
  List<OrderItem> get kotItems => items.where((i) => i.hasKot).toList();
  
  bool get hasPendingItems => pendingItems.isNotEmpty;
  bool get hasKotItems => kotItems.isNotEmpty;

  double calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + item.itemTotal);
  }

  Order recalculate({
    double taxRate = 0.0, // No tax by default for Captain running total
    double serviceChargeRate = 0.0, // No service charge by default
    double? discount,
    bool includeTaxAndCharges = false,
  }) {
    final newSubtotal = calculateSubtotal();
    final newTax = includeTaxAndCharges ? newSubtotal * taxRate : 0.0;
    final newDiscount = discount ?? discountAmount;
    final newServiceCharge = includeTaxAndCharges ? newSubtotal * serviceChargeRate : 0.0;
    final total = newSubtotal + newTax + newServiceCharge - newDiscount;
    final roundedTotal = (total).round().toDouble();
    final newRoundOff = roundedTotal - total;

    return copyWith(
      subtotal: newSubtotal,
      taxAmount: newTax,
      discountAmount: newDiscount,
      serviceCharge: newServiceCharge,
      roundOff: newRoundOff,
      grandTotal: roundedTotal,
    );
  }

  Order copyWith({
    String? id,
    String? tableId,
    String? tableName,
    OrderType? type,
    OrderStatus? status,
    List<OrderItem>? items,
    String? customerId,
    String? customerName,
    String? customerPhone,
    int? guestCount,
    String? captainId,
    String? captainName,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? serviceCharge,
    double? roundOff,
    double? grandTotal,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      type: type ?? this.type,
      status: status ?? this.status,
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      guestCount: guestCount ?? this.guestCount,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableId': tableId,
    'tableName': tableName,
    'type': type.name,
    'status': status.name,
    'items': items.map((i) => i.toJson()).toList(),
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'guestCount': guestCount,
    'captainId': captainId,
    'captainName': captainName,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'serviceCharge': serviceCharge,
    'roundOff': roundOff,
    'grandTotal': grandTotal,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    tableId: json['tableId'] as String,
    tableName: json['tableName'] as String,
    type: OrderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OrderType.dineIn,
    ),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderStatus.active,
    ),
    items: (json['items'] as List<dynamic>?)
        ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList() ?? [],
    customerId: json['customerId'] as String?,
    customerName: json['customerName'] as String?,
    customerPhone: json['customerPhone'] as String?,
    guestCount: json['guestCount'] as int? ?? 1,
    captainId: json['captainId'] as String,
    captainName: json['captainName'] as String,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
    roundOff: (json['roundOff'] as num?)?.toDouble() ?? 0,
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  List<Object?> get props => [
    id, tableId, tableName, type, status, items, customerId, customerName,
    customerPhone, guestCount, captainId, captainName, subtotal, taxAmount,
    discountAmount, serviceCharge, roundOff, grandTotal, notes, createdAt, updatedAt,
  ];
}
