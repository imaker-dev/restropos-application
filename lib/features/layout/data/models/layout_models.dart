/// API Models for Layout Module (Floors & Sections)

class Floor {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final int? outletId;
  final int? floorNumber;
  final int? displayOrder;
  final bool isActive;
  final int? tableCount;
  final int? availableCount;
  final int? occupiedCount;
  final List<Section>? sections;
  final List<ApiTable>? tables;

  const Floor({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.outletId,
    this.floorNumber,
    this.displayOrder,
    this.isActive = true,
    this.tableCount,
    this.availableCount,
    this.occupiedCount,
    this.sections,
    this.tables,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    // Parse isActive from various formats (bool, int, string)
    bool parseIsActive(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return true;
    }

    return Floor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      description: json['description'] as String?,
      outletId: json['outlet_id'] as int? ?? json['outletId'] as int?,
      floorNumber: json['floor_number'] as int? ?? json['floorNumber'] as int?,
      displayOrder:
          json['display_order'] as int? ??
          json['displayOrder'] as int? ??
          json['sortOrder'] as int?,
      isActive: parseIsActive(json['is_active'] ?? json['isActive']),
      tableCount: json['table_count'] as int? ?? json['tableCount'] as int?,
      availableCount:
          json['available_count'] as int? ?? json['availableCount'] as int?,
      occupiedCount:
          json['occupied_count'] as int? ?? json['occupiedCount'] as int?,
      sections: (json['sections'] as List?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      tables: (json['tables'] as List?)
          ?.map((e) => ApiTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'outletId': outletId,
    'floorNumber': floorNumber,
    'displayOrder': displayOrder,
    'isActive': isActive,
  };
}

class Section {
  final int id;
  final String name;
  final String? code;
  final String? colorCode;
  final String? sectionType;
  final int? floorId;
  final int? outletId;
  final int? displayOrder;
  final bool isActive;
  final List<ApiTable>? tables;

  const Section({
    required this.id,
    required this.name,
    this.code,
    this.colorCode,
    this.sectionType,
    this.floorId,
    this.outletId,
    this.displayOrder,
    this.isActive = true,
    this.tables,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    // Parse isActive from various formats (bool, int, string)
    bool parseIsActive(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return true;
    }

    return Section(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      colorCode: json['color_code'] as String? ?? json['colorCode'] as String?,
      sectionType:
          json['section_type'] as String? ?? json['sectionType'] as String?,
      floorId: json['floor_id'] as int? ?? json['floorId'] as int?,
      outletId: json['outlet_id'] as int? ?? json['outletId'] as int?,
      displayOrder:
          json['display_order'] as int? ??
          json['displayOrder'] as int? ??
          json['sortOrder'] as int?,
      isActive: parseIsActive(json['is_active'] ?? json['isActive']),
      tables: (json['tables'] as List?)
          ?.map((e) => ApiTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'floorId': floorId,
    'outletId': outletId,
    'displayOrder': displayOrder,
    'isActive': isActive,
  };
}

class ApiTable {
  final int id;
  final String? tableNumber;
  final String name;
  final String status;
  final int? capacity;
  final int? floorId;
  final int? sectionId;
  final String? sectionName;
  final int? currentOrderId;
  final int? currentCovers;
  final double? orderTotal;
  final int? kotPending;
  final double? runningTotal;
  final int? guestCount;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final DateTime? sessionStart;
  final String? captainName;
  final int? captainId;
  final double? positionX;
  final double? positionY;
  final List<int>? mergedTableIds;
  final int? primaryTableId;
  final bool isMerged;

  const ApiTable({
    required this.id,
    this.tableNumber,
    required this.name,
    required this.status,
    this.capacity,
    this.floorId,
    this.sectionId,
    this.sectionName,
    this.currentOrderId,
    this.currentCovers,
    this.orderTotal,
    this.kotPending,
    this.runningTotal,
    this.guestCount,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.sessionStart,
    this.captainName,
    this.captainId,
    this.positionX,
    this.positionY,
    this.mergedTableIds,
    this.primaryTableId,
    this.isMerged = false,
  });

  factory ApiTable.fromJson(Map<String, dynamic> json) {
    // Parse table_number from either snake_case or camelCase
    final tableNum =
        json['table_number'] as String? ?? json['tableNumber'] as String?;

    // Treat empty or null status as 'available'
    final rawStatus = json['status'] as String? ?? '';
    final status = rawStatus.trim().isEmpty ? 'available' : rawStatus;

    return ApiTable(
      id: json['id'] as int? ?? 0,
      tableNumber: tableNum,
      name: json['name'] as String? ?? tableNum ?? '',
      status: status,
      capacity: json['capacity'] as int?,
      floorId: json['floor_id'] as int? ?? json['floorId'] as int?,
      sectionId: json['section_id'] as int? ?? json['sectionId'] as int?,
      sectionName:
          json['section_name'] as String? ?? json['sectionName'] as String?,
      currentOrderId:
          json['current_order_id'] as int? ?? json['currentOrderId'] as int?,
      currentCovers:
          json['current_covers'] as int? ?? json['currentCovers'] as int?,
      orderTotal:
          (json['order_total'] as num?)?.toDouble() ??
          (json['orderTotal'] as num?)?.toDouble(),
      kotPending: json['kot_pending'] as int? ?? json['kotPending'] as int?,
      runningTotal: (json['runningTotal'] as num?)?.toDouble(),
      guestCount:
          json['guest_count'] as int? ??
          json['guestCount'] as int? ??
          json['current_covers'] as int?,
      customerName:
          json['guest_name'] as String? ??
          json['customerName'] as String? ??
          json['customer_name'] as String?,
      customerPhone:
          json['guest_phone'] as String? ??
          json['customerPhone'] as String? ??
          json['customer_phone'] as String?,
      notes: json['notes'] as String?,
      sessionStart: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : json['session_start'] != null
          ? DateTime.tryParse(json['session_start'] as String)
          : json['sessionStart'] != null
          ? DateTime.tryParse(json['sessionStart'] as String)
          : null,
      captainName:
          json['captainName'] as String? ?? json['captain_name'] as String?,
      captainId: json['captainId'] as int? ?? json['captain_id'] as int?,
      positionX:
          (json['position_x'] as num?)?.toDouble() ??
          (json['positionX'] as num?)?.toDouble(),
      positionY:
          (json['position_y'] as num?)?.toDouble() ??
          (json['positionY'] as num?)?.toDouble(),
      mergedTableIds: (json['mergedTableIds'] as List?)
          ?.map((e) => e as int)
          .toList(),
      primaryTableId:
          json['primaryTableId'] as int? ?? json['primary_table_id'] as int?,
      isMerged:
          json['isMerged'] as bool? ?? json['is_merged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableNumber': tableNumber,
    'name': name,
    'status': status,
    'capacity': capacity,
    'floorId': floorId,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'currentOrderId': currentOrderId,
    'runningTotal': runningTotal,
    'guestCount': guestCount,
    'customerName': customerName,
    'isMerged': isMerged,
  };

  String get displayName => tableNumber ?? name;
  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isRunning => status == 'running' || status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isBilling => status == 'billing';
  bool get isCleaning => status == 'cleaning';
  bool get hasBill => status == 'billed' || status == 'billing';
}

class StartSessionRequest {
  final int guestCount;
  final String? guestName;
  final String? guestPhone;
  final String? notes;

  const StartSessionRequest({
    required this.guestCount,
    this.guestName,
    this.guestPhone,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'guestCount': guestCount,
    if (guestName != null) 'guestName': guestName,
    if (guestPhone != null) 'guestPhone': guestPhone,
    if (notes != null) 'notes': notes,
  };
}

/// Response from POST /tables/{tableId}/session
class StartSessionResponse {
  final int sessionId;
  final ApiTable table;

  const StartSessionResponse({required this.sessionId, required this.table});

  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    return StartSessionResponse(
      sessionId: json['sessionId'] as int? ?? 0,
      table: ApiTable.fromJson(json['table'] as Map<String, dynamic>),
    );
  }
}

class TableSession {
  final int sessionId;
  final int tableId;
  final String? tableNumber;
  final String status;
  final int covers;
  final String? customerName;
  final String? customerPhone;
  final DateTime startTime;
  final String? duration;
  final int? captainId;
  final String? captainName;
  final List<SessionOrder>? orders;

  const TableSession({
    required this.sessionId,
    required this.tableId,
    this.tableNumber,
    required this.status,
    required this.covers,
    this.customerName,
    this.customerPhone,
    required this.startTime,
    this.duration,
    this.captainId,
    this.captainName,
    this.orders,
  });

  factory TableSession.fromJson(Map<String, dynamic> json) {
    return TableSession(
      sessionId: json['sessionId'] as int? ?? 0,
      tableId: json['tableId'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String?,
      status: json['status'] as String? ?? 'occupied',
      covers: json['covers'] as int? ?? 1,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      startTime:
          DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      duration: json['duration'] as String?,
      captainId: json['captainId'] as int?,
      captainName: json['captainName'] as String?,
      orders: (json['orders'] as List?)
          ?.map((e) => SessionOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SessionOrder {
  final int orderId;
  final String orderNumber;
  final String status;
  final double total;
  final int? kotCount;

  const SessionOrder({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.total,
    this.kotCount,
  });

  factory SessionOrder.fromJson(Map<String, dynamic> json) {
    return SessionOrder(
      orderId: json['orderId'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      kotCount: json['kotCount'] as int?,
    );
  }
}

class MergeTablesRequest {
  final List<int> tableIds;

  const MergeTablesRequest({required this.tableIds});

  Map<String, dynamic> toJson() => {'tableIds': tableIds};
}
