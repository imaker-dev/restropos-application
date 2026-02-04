import 'package:equatable/equatable.dart';
import 'order_item.dart';

enum KotStatus {
  pending,
  sent,
  preparing,
  ready,
  printed,
  cancelled,
}

class Kot extends Equatable {
  final String id;
  final String orderId;
  final String tableId;
  final String tableName;
  final int kotNumber;
  final List<OrderItem> items;
  final KotStatus status;
  final String? notes;
  final String captainId;
  final String captainName;
  final DateTime createdAt;
  final DateTime? printedAt;

  const Kot({
    required this.id,
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.kotNumber,
    this.items = const [],
    this.status = KotStatus.pending,
    this.notes,
    required this.captainId,
    required this.captainName,
    required this.createdAt,
    this.printedAt,
  });

  bool get isPending => status == KotStatus.pending;
  bool get isPrinted => status == KotStatus.printed;
  bool get canPrint => status == KotStatus.pending || status == KotStatus.sent;

  Kot copyWith({
    String? id,
    String? orderId,
    String? tableId,
    String? tableName,
    int? kotNumber,
    List<OrderItem>? items,
    KotStatus? status,
    String? notes,
    String? captainId,
    String? captainName,
    DateTime? createdAt,
    DateTime? printedAt,
  }) {
    return Kot(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      kotNumber: kotNumber ?? this.kotNumber,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      createdAt: createdAt ?? this.createdAt,
      printedAt: printedAt ?? this.printedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'tableId': tableId,
    'tableName': tableName,
    'kotNumber': kotNumber,
    'items': items.map((i) => i.toJson()).toList(),
    'status': status.name,
    'notes': notes,
    'captainId': captainId,
    'captainName': captainName,
    'createdAt': createdAt.toIso8601String(),
    'printedAt': printedAt?.toIso8601String(),
  };

  factory Kot.fromJson(Map<String, dynamic> json) => Kot(
    id: json['id'] as String,
    orderId: json['orderId'] as String,
    tableId: json['tableId'] as String,
    tableName: json['tableName'] as String,
    kotNumber: json['kotNumber'] as int,
    items: (json['items'] as List<dynamic>?)
        ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList() ?? [],
    status: KotStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => KotStatus.pending,
    ),
    notes: json['notes'] as String?,
    captainId: json['captainId'] as String,
    captainName: json['captainName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    printedAt: json['printedAt'] != null
        ? DateTime.parse(json['printedAt'] as String)
        : null,
  );

  @override
  List<Object?> get props => [
    id, orderId, tableId, tableName, kotNumber, items, status,
    notes, captainId, captainName, createdAt, printedAt,
  ];
}
