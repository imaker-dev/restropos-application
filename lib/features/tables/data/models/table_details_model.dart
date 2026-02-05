/// API Models for Table Details endpoint (/tables/{tableId})

class TableDetailsResponse {
  final int id;
  final String tableNumber;
  final String? name;
  final String status;
  final int capacity;
  final int minCapacity;
  final String shape;
  final bool isMergeable;
  final bool isSplittable;
  final String? qrCode;
  final TableLocation location;
  final TablePosition position;
  final TableSessionDetails? session;
  final TableCaptain? captain;
  final TableOrderDetails? order;
  final List<TableOrderItem> items;
  final List<TableKot> kots;
  final TableBilling? billing;
  final List<TableTimelineEvent> timeline;
  final List<MergedTableInfo> mergedTables;
  final TableStatusSummary statusSummary;

  const TableDetailsResponse({
    required this.id,
    required this.tableNumber,
    this.name,
    required this.status,
    required this.capacity,
    this.minCapacity = 1,
    required this.shape,
    this.isMergeable = false,
    this.isSplittable = false,
    this.qrCode,
    required this.location,
    required this.position,
    this.session,
    this.captain,
    this.order,
    this.items = const [],
    this.kots = const [],
    this.billing,
    this.timeline = const [],
    this.mergedTables = const [],
    required this.statusSummary,
  });

  factory TableDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TableDetailsResponse(
      id: json['id'] as int? ?? 0,
      tableNumber: json['tableNumber'] as String? ?? '',
      name: json['name'] as String?,
      status: json['status'] as String? ?? 'available',
      capacity: json['capacity'] as int? ?? 4,
      minCapacity: json['minCapacity'] as int? ?? 1,
      shape: json['shape'] as String? ?? 'square',
      isMergeable: json['isMergeable'] as bool? ?? false,
      isSplittable: json['isSplittable'] as bool? ?? false,
      qrCode: json['qrCode'] as String?,
      location: json['location'] != null
          ? TableLocation.fromJson(json['location'] as Map<String, dynamic>)
          : const TableLocation(),
      position: json['position'] != null
          ? TablePosition.fromJson(json['position'] as Map<String, dynamic>)
          : const TablePosition(),
      session: json['session'] != null
          ? TableSessionDetails.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      captain: json['captain'] != null
          ? TableCaptain.fromJson(json['captain'] as Map<String, dynamic>)
          : null,
      order: json['order'] != null
          ? TableOrderDetails.fromJson(json['order'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List?)
          ?.map((e) => TableOrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      kots: (json['kots'] as List?)
          ?.map((e) => TableKot.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      billing: json['billing'] != null
          ? TableBilling.fromJson(json['billing'] as Map<String, dynamic>)
          : null,
      timeline: (json['timeline'] as List?)
          ?.map((e) => TableTimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      mergedTables: (json['mergedTables'] as List?)
          ?.map((e) => MergedTableInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      statusSummary: json['statusSummary'] != null
          ? TableStatusSummary.fromJson(json['statusSummary'] as Map<String, dynamic>)
          : const TableStatusSummary(message: ''),
    );
  }

  String get displayName => name ?? tableNumber;
  bool get hasActiveSession => session != null;
  bool get hasActiveOrder => order != null;
  bool get hasItems => items.isNotEmpty;
  bool get hasKots => kots.isNotEmpty;
  int get pendingKotCount => kots.where((k) => k.status == 'pending').length;
  int get readyKotCount => kots.where((k) => k.status == 'ready').length;
}

class TableLocation {
  final int? outletId;
  final String? outletName;
  final int? floorId;
  final String? floorName;
  final int? sectionId;
  final String? sectionName;
  final String? sectionType;

  const TableLocation({
    this.outletId,
    this.outletName,
    this.floorId,
    this.floorName,
    this.sectionId,
    this.sectionName,
    this.sectionType,
  });

  factory TableLocation.fromJson(Map<String, dynamic> json) {
    return TableLocation(
      outletId: json['outletId'] as int?,
      outletName: json['outletName'] as String?,
      floorId: json['floorId'] as int?,
      floorName: json['floorName'] as String?,
      sectionId: json['sectionId'] as int?,
      sectionName: json['sectionName'] as String?,
      sectionType: json['sectionType'] as String?,
    );
  }
}

class TablePosition {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const TablePosition({
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
    this.rotation = 0,
  });

  factory TablePosition.fromJson(Map<String, dynamic> json) {
    return TablePosition(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 100,
      height: (json['height'] as num?)?.toDouble() ?? 100,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TableSessionDetails {
  final int id;
  final int guestCount;
  final String? guestName;
  final String? guestPhone;
  final DateTime startedAt;
  final int duration; // in minutes
  final String? notes;

  const TableSessionDetails({
    required this.id,
    required this.guestCount,
    this.guestName,
    this.guestPhone,
    required this.startedAt,
    this.duration = 0,
    this.notes,
  });

  factory TableSessionDetails.fromJson(Map<String, dynamic> json) {
    return TableSessionDetails(
      id: json['id'] as int? ?? 0,
      guestCount: json['guestCount'] as int? ?? 1,
      guestName: json['guestName'] as String?,
      guestPhone: json['guestPhone'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      duration: json['duration'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  String get formattedDuration {
    if (duration < 60) return '${duration}m';
    final hours = duration ~/ 60;
    final mins = duration % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

class TableCaptain {
  final int id;
  final String name;
  final String? employeeCode;
  final String? phone;

  const TableCaptain({
    required this.id,
    required this.name,
    this.employeeCode,
    this.phone,
  });

  factory TableCaptain.fromJson(Map<String, dynamic> json) {
    return TableCaptain(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      employeeCode: json['employeeCode'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class TableOrderDetails {
  final int id;
  final String orderNumber;
  final String orderType;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double serviceCharge;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? specialInstructions;
  final DateTime createdAt;

  const TableOrderDetails({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    this.paymentStatus = 'pending',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.serviceCharge = 0,
    this.totalAmount = 0,
    this.customerName,
    this.customerPhone,
    this.specialInstructions,
    required this.createdAt,
  });

  factory TableOrderDetails.fromJson(Map<String, dynamic> json) {
    return TableOrderDetails(
      id: json['id'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      orderType: json['orderType'] as String? ?? 'dine_in',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TableOrderItem {
  final int id;
  final int itemId;
  final String name;
  final String? shortName;
  final int? variantId;
  final String? variantName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String status;
  final String? itemType;
  final String? station;
  final String? stationType;
  final String? specialInstructions;
  final bool isComplimentary;
  final List<ItemAddon> addons;

  const TableOrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    this.shortName,
    this.variantId,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.itemType,
    this.station,
    this.stationType,
    this.specialInstructions,
    this.isComplimentary = false,
    this.addons = const [],
  });

  factory TableOrderItem.fromJson(Map<String, dynamic> json) {
    return TableOrderItem(
      id: json['id'] as int? ?? 0,
      itemId: json['itemId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      variantId: json['variantId'] as int?,
      variantName: json['variantName'] as String?,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      itemType: json['itemType'] as String?,
      station: json['station'] as String?,
      stationType: json['stationType'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      isComplimentary: json['isComplimentary'] as bool? ?? false,
      addons: (json['addons'] as List?)
          ?.map((e) => ItemAddon.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  bool get isVeg => itemType == 'veg';
  bool get isNonVeg => itemType == 'non_veg';
  bool get hasAddons => addons.isNotEmpty;
  String get displayName => variantName != null ? '$name ($variantName)' : name;
}

class ItemAddon {
  final int id;
  final String name;
  final String? groupName;
  final double price;
  final int quantity;

  const ItemAddon({
    required this.id,
    required this.name,
    this.groupName,
    required this.price,
    this.quantity = 1,
  });

  factory ItemAddon.fromJson(Map<String, dynamic> json) {
    return ItemAddon(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      groupName: json['groupName'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class TableKot {
  final int id;
  final String kotNumber;
  final String status;
  final String? station;
  final int itemCount;
  final int priority;
  final int? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final DateTime createdAt;

  const TableKot({
    required this.id,
    required this.kotNumber,
    required this.status,
    this.station,
    this.itemCount = 0,
    this.priority = 0,
    this.acceptedBy,
    this.acceptedAt,
    this.readyAt,
    this.servedAt,
    required this.createdAt,
  });

  factory TableKot.fromJson(Map<String, dynamic> json) {
    return TableKot(
      id: json['id'] as int? ?? 0,
      kotNumber: json['kotNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      station: json['station'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
      priority: json['priority'] as int? ?? 0,
      acceptedBy: json['acceptedBy'] as int?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'] as String)
          : null,
      servedAt: json['servedAt'] != null
          ? DateTime.tryParse(json['servedAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isReady => status == 'ready';
  bool get isServed => status == 'served';
}

class TableBilling {
  final int? invoiceId;
  final String? invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double serviceCharge;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final DateTime? generatedAt;

  const TableBilling({
    this.invoiceId,
    this.invoiceNumber,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.serviceCharge = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.paymentStatus = 'pending',
    this.generatedAt,
  });

  factory TableBilling.fromJson(Map<String, dynamic> json) {
    return TableBilling(
      invoiceId: json['invoiceId'] as int?,
      invoiceNumber: json['invoiceNumber'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
    );
  }
}

class TableTimelineEvent {
  final String? details;
  final DateTime timestamp;

  const TableTimelineEvent({
    this.details,
    required this.timestamp,
  });

  factory TableTimelineEvent.fromJson(Map<String, dynamic> json) {
    return TableTimelineEvent(
      details: json['details'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class MergedTableInfo {
  final int id;
  final int primaryTableId;
  final int mergedTableId;
  final int? tableSessionId;
  final int? mergedBy;
  final DateTime mergedAt;
  final DateTime? unmergedAt;
  final int? unmergedBy;
  final String mergedTableNumber;

  const MergedTableInfo({
    required this.id,
    required this.primaryTableId,
    required this.mergedTableId,
    this.tableSessionId,
    this.mergedBy,
    required this.mergedAt,
    this.unmergedAt,
    this.unmergedBy,
    required this.mergedTableNumber,
  });

  factory MergedTableInfo.fromJson(Map<String, dynamic> json) {
    return MergedTableInfo(
      id: json['id'] as int? ?? 0,
      primaryTableId: json['primary_table_id'] as int? ?? json['primaryTableId'] as int? ?? 0,
      mergedTableId: json['merged_table_id'] as int? ?? json['mergedTableId'] as int? ?? 0,
      tableSessionId: json['table_session_id'] as int? ?? json['tableSessionId'] as int?,
      mergedBy: json['merged_by'] as int? ?? json['mergedBy'] as int?,
      mergedAt: DateTime.tryParse(json['merged_at'] as String? ?? json['mergedAt'] as String? ?? '') ?? DateTime.now(),
      unmergedAt: json['unmerged_at'] != null
          ? DateTime.tryParse(json['unmerged_at'] as String)
          : json['unmergedAt'] != null
          ? DateTime.tryParse(json['unmergedAt'] as String)
          : null,
      unmergedBy: json['unmerged_by'] as int? ?? json['unmergedBy'] as int?,
      mergedTableNumber: json['merged_table_number'] as String? ?? json['mergedTableNumber'] as String? ?? '',
    );
  }
}

class TableStatusSummary {
  final String message;
  final bool? canSeat;
  final int? guestCount;
  final int? duration;
  final String? orderNumber;
  final int? itemCount;
  final int? servedItems;
  final double? orderTotal;
  final int? pendingKots;
  final int? readyKots;
  final String? orderStatus;

  const TableStatusSummary({
    required this.message,
    this.canSeat,
    this.guestCount,
    this.duration,
    this.orderNumber,
    this.itemCount,
    this.servedItems,
    this.orderTotal,
    this.pendingKots,
    this.readyKots,
    this.orderStatus,
  });

  factory TableStatusSummary.fromJson(Map<String, dynamic> json) {
    return TableStatusSummary(
      message: json['message'] as String? ?? '',
      canSeat: json['canSeat'] as bool?,
      guestCount: json['guestCount'] as int?,
      duration: json['duration'] as int?,
      orderNumber: json['orderNumber'] as String?,
      itemCount: json['itemCount'] as int?,
      servedItems: json['servedItems'] as int?,
      orderTotal: (json['orderTotal'] as num?)?.toDouble(),
      pendingKots: json['pendingKots'] as int?,
      readyKots: json['readyKots'] as int?,
      orderStatus: json['orderStatus'] as String?,
    );
  }
}
