import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum TableStatus {
  available,
  occupied,
  running,
  billing,
  cleaning,
  blocked,
  reserved,
}

extension TableStatusExtension on TableStatus {
  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.running:
        return 'Running';
      case TableStatus.billing:
        return 'Billing';
      case TableStatus.cleaning:
        return 'Cleaning';
      case TableStatus.blocked:
        return 'Blocked';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }

  Color get color {
    switch (this) {
      case TableStatus.available:
        return AppColors.tableAvailable;
      case TableStatus.occupied:
        return AppColors.tableOccupied;
      case TableStatus.running:
        return AppColors.tableRunning;
      case TableStatus.billing:
        return AppColors.tableBilling;
      case TableStatus.cleaning:
        return AppColors.tableCleaning;
      case TableStatus.blocked:
        return AppColors.tableBlocked;
      case TableStatus.reserved:
        return AppColors.tableReserved;
    }
  }

  bool get canTakeOrder => this == TableStatus.available || this == TableStatus.running || this == TableStatus.occupied;
  bool get hasOrder => this != TableStatus.available && this != TableStatus.cleaning && this != TableStatus.blocked;
  bool get canPrint => this == TableStatus.running || this == TableStatus.occupied;
  bool get canPay => this == TableStatus.billing;
  bool get isAvailableForSeating => this == TableStatus.available;
  bool get needsCleaning => this == TableStatus.cleaning;
  bool get isBlocked => this == TableStatus.blocked;
  bool get isReserved => this == TableStatus.reserved;
}

class TableSection extends Equatable {
  final String id;
  final String name;
  final String floorId;
  final int sortOrder;

  const TableSection({
    required this.id,
    required this.name,
    required this.floorId,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, floorId, sortOrder];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'floorId': floorId,
    'sortOrder': sortOrder,
  };

  factory TableSection.fromJson(Map<String, dynamic> json) => TableSection(
    id: json['id'] as String,
    name: json['name'] as String,
    floorId: json['floorId'] as String,
    sortOrder: json['sortOrder'] as int? ?? 0,
  );
}

class RestaurantTable extends Equatable {
  final String id;
  final String name;
  final String sectionId;
  final String sectionName;
  final TableStatus status;
  final int capacity;
  final String? currentOrderId;
  final String? lockedByUserId;
  final String? lockedByUserName;
  final DateTime? orderStartedAt;
  final double? runningTotal;
  final int? guestCount;
  final int sortOrder;

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.sectionId,
    required this.sectionName,
    this.status = TableStatus.available,
    this.capacity = 4,
    this.currentOrderId,
    this.lockedByUserId,
    this.lockedByUserName,
    this.orderStartedAt,
    this.runningTotal,
    this.guestCount,
    this.sortOrder = 0,
  });

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status != TableStatus.available;
  bool get isLocked => status == TableStatus.blocked;

  RestaurantTable copyWith({
    String? id,
    String? name,
    String? sectionId,
    String? sectionName,
    TableStatus? status,
    int? capacity,
    String? currentOrderId,
    String? lockedByUserId,
    String? lockedByUserName,
    DateTime? orderStartedAt,
    double? runningTotal,
    int? guestCount,
    int? sortOrder,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      lockedByUserId: lockedByUserId ?? this.lockedByUserId,
      lockedByUserName: lockedByUserName ?? this.lockedByUserName,
      orderStartedAt: orderStartedAt ?? this.orderStartedAt,
      runningTotal: runningTotal ?? this.runningTotal,
      guestCount: guestCount ?? this.guestCount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'status': status.name,
    'capacity': capacity,
    'currentOrderId': currentOrderId,
    'lockedByUserId': lockedByUserId,
    'lockedByUserName': lockedByUserName,
    'orderStartedAt': orderStartedAt?.toIso8601String(),
    'runningTotal': runningTotal,
    'guestCount': guestCount,
    'sortOrder': sortOrder,
  };

  factory RestaurantTable.fromJson(Map<String, dynamic> json) => RestaurantTable(
    id: json['id'] as String,
    name: json['name'] as String,
    sectionId: json['sectionId'] as String,
    sectionName: json['sectionName'] as String,
    status: TableStatus.values.firstWhere(
          (e) => e.name == json['status'],
      orElse: () => TableStatus.available,
    ),
    capacity: json['capacity'] as int? ?? 4,
    currentOrderId: json['currentOrderId'] as String?,
    lockedByUserId: json['lockedByUserId'] as String?,
    lockedByUserName: json['lockedByUserName'] as String?,
    orderStartedAt: json['orderStartedAt'] != null
        ? DateTime.parse(json['orderStartedAt'] as String)
        : null,
    runningTotal: (json['runningTotal'] as num?)?.toDouble(),
    guestCount: json['guestCount'] as int?,
    sortOrder: json['sortOrder'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    sectionId,
    sectionName,
    status,
    capacity,
    currentOrderId,
    lockedByUserId,
    lockedByUserName,
    orderStartedAt,
    runningTotal,
    guestCount,
    sortOrder,
  ];
}
