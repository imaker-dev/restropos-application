import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../layout/data/models/layout_models.dart';
import '../../../layout/data/repositories/layout_repository.dart';
import '../../domain/entities/table_entity.dart';

// Floors provider - fetches floors from API or user's assigned floors
final floorsProvider = FutureProvider<List<Floor>>((ref) async {
  final repository = ref.watch(layoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  // Parse outletId from dynamic to int
  int outletId = 4; // Default outlet ID
  if (user?.primaryOutletId != null) {
    final dynamic rawId = user!.primaryOutletId;
    if (rawId is int) {
      outletId = rawId;
    } else if (rawId is String) {
      outletId = int.tryParse(rawId) ?? 4;
    }
  }

  // Get floors from API
  final result = await repository.getFloors(outletId);

  return result.when(
    success: (floors, _) {
      // Filter by user's assigned floors if available
      if (user != null && user.assignedFloors.isNotEmpty) {
        return floors.where((f) => user.assignedFloors.contains(f.id)).toList();
      }
      return floors;
    },
    failure: (_, __, ___) => <Floor>[],
  );
});

// Selected floor provider
final selectedFloorProvider = StateProvider<int?>((ref) {
  return null; // null means show first floor or all
});

// Sections provider - fetches sections from floor details
final sectionsProvider = Provider<List<TableSection>>((ref) {
  // Sections are derived from tables grouped by sectionId and sectionName
  final tables = ref.watch(tablesProvider).tables;
  final currentFloorId = ref.watch(selectedFloorProvider);
  final floorIdStr = currentFloorId?.toString() ?? '';

  // Group by sectionId to get unique sections
  final sectionMap = <String, String>{};
  for (final table in tables) {
    sectionMap[table.sectionId] = table.sectionName;
  }

  return sectionMap.entries
      .map(
        (entry) =>
            TableSection(id: entry.key, name: entry.value, floorId: floorIdStr),
      )
      .toList();
});

// Selected section provider
final selectedSectionProvider = StateProvider<String?>((ref) {
  return null; // null means show all sections
});

// Selected status filter provider - null means show all
final selectedStatusFilterProvider = StateProvider<TableStatus?>((ref) {
  return null;
});

// Tables provider with optimistic updates
final tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((
  ref,
) {
  final repository = ref.watch(layoutRepositoryProvider);
  final notifier = TablesNotifier(repository, ref);

  // Subscribe to WebSocket table updates
  final tableSubscription = ref.listen<AsyncValue<Map<String, dynamic>>>(
    tableUpdatesProvider,
    (previous, next) {
      next.whenData((data) {
        notifier.handleWebSocketTableUpdate(data);
      });
    },
  );

  // Subscribe to WebSocket order updates
  final orderSubscription = ref.listen<AsyncValue<Map<String, dynamic>>>(
    orderUpdatesProvider,
    (previous, next) {
      next.whenData((data) {
        notifier.handleOrderUpdate(data);
      });
    },
  );

  // Subscribe to WebSocket bill status updates
  final billSubscription = ref.listen<AsyncValue<Map<String, dynamic>>>(
    billStatusProvider,
    (previous, next) {
      next.whenData((data) {
        notifier.handleBillStatusUpdate(data);
      });
    },
  );

  ref.onDispose(() {
    tableSubscription.close();
    orderSubscription.close();
    billSubscription.close();
  });

  return notifier;
});

// Filtered tables by section
final filteredTablesProvider = Provider<List<RestaurantTable>>((ref) {
  final tablesState = ref.watch(tablesProvider);
  final selectedSection = ref.watch(selectedSectionProvider);

  if (selectedSection == null) {
    return tablesState.tables;
  }

  return tablesState.tables
      .where((t) => t.sectionId == selectedSection)
      .toList();
});

// Tables grouped by section with optional status filter
final tablesGroupedBySectionProvider =
    Provider<Map<String, List<RestaurantTable>>>((ref) {
      final tables = ref.watch(tablesProvider).tables;
      final sections = ref.watch(sectionsProvider);
      final statusFilter = ref.watch(selectedStatusFilterProvider);

      final Map<String, List<RestaurantTable>> grouped = {};

      for (final section in sections) {
        var sectionTables = tables.where((t) => t.sectionId == section.id);

        // Apply status filter if selected
        if (statusFilter != null) {
          sectionTables = sectionTables.where((t) => t.status == statusFilter);
        }

        final tablesList = sectionTables.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        // Only include sections that have tables after filtering
        if (tablesList.isNotEmpty) {
          grouped[section.name] = tablesList;
        }
      }

      return grouped;
    });

// Single table provider for optimized rebuilds
final tableProvider = Provider.family<RestaurantTable?, String>((ref, tableId) {
  final tables = ref.watch(tablesProvider).tables;
  try {
    return tables.firstWhere((t) => t.id == tableId);
  } catch (_) {
    return null;
  }
});

// Selected table provider
final selectedTableProvider = StateProvider<String?>((ref) => null);

// Table counts by status
final tableCountsProvider = Provider<Map<TableStatus, int>>((ref) {
  final tables = ref.watch(tablesProvider).tables;
  final Map<TableStatus, int> counts = {};

  for (final status in TableStatus.values) {
    counts[status] = tables.where((t) => t.status == status).length;
  }

  return counts;
});

class TablesState {
  final List<RestaurantTable> tables;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  final int? currentFloorId;

  TablesState({
    required this.tables,
    this.isLoading = false,
    this.error,
    DateTime? lastUpdated,
    this.currentFloorId,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  TablesState copyWith({
    List<RestaurantTable>? tables,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    int? currentFloorId,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
      currentFloorId: currentFloorId ?? this.currentFloorId,
    );
  }

  factory TablesState.initial() => TablesState(tables: []);
}

class TablesNotifier extends StateNotifier<TablesState> {
  final LayoutRepository? _repository;
  final Ref? _ref;

  TablesNotifier([this._repository, this._ref]) : super(TablesState.initial());

  /// Load tables from floor details API (includes tables in response)
  Future<void> loadTablesByFloorDetails(int floorId) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getFloorDetails(floorId);

    result.when(
      success: (floor, _) {
        final apiTables = floor.tables ?? [];
        final tables = apiTables.map((t) => _mapApiTableToEntity(t)).toList();
        state = state.copyWith(
          tables: tables,
          isLoading: false,
          currentFloorId: floorId,
        );
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  /// Load tables from API by floor (fallback)
  Future<void> loadTablesByFloor(int floorId) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTablesByFloor(floorId);

    result.when(
      success: (apiTables, _) {
        final tables = apiTables.map((t) => _mapApiTableToEntity(t)).toList();
        state = state.copyWith(
          tables: tables,
          isLoading: false,
          currentFloorId: floorId,
        );
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  /// Load tables from API by outlet
  Future<void> loadTablesByOutlet(int outletId) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTablesByOutlet(outletId);

    result.when(
      success: (apiTables, _) {
        final tables = apiTables.map((t) => _mapApiTableToEntity(t)).toList();
        state = state.copyWith(tables: tables, isLoading: false);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  /// Map API table to domain entity
  RestaurantTable _mapApiTableToEntity(ApiTable apiTable) {
    return RestaurantTable(
      id: apiTable.id.toString(),
      name: apiTable.tableNumber ?? apiTable.name,
      sectionId: apiTable.sectionId?.toString() ?? '',
      sectionName: apiTable.sectionName ?? '',
      status: _mapApiStatusToTableStatus(apiTable.status),
      capacity: apiTable.capacity ?? 4,
      sortOrder: apiTable.id, // Use ID as sort order fallback
      guestCount: apiTable.currentCovers,
      runningTotal: apiTable.orderTotal ?? apiTable.runningTotal,
      orderStartedAt: apiTable.sessionStart,
      lockedByUserId: apiTable.captainId?.toString(),
      lockedByUserName: apiTable.captainName,
    );
  }

  /// Map API status string to TableStatus enum
  TableStatus _mapApiStatusToTableStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'running':
        return TableStatus.running;
      case 'billing':
      case 'billed':
        return TableStatus.billing;
      case 'cleaning':
        return TableStatus.cleaning;
      case 'blocked':
        return TableStatus.blocked;
      case 'reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }

  /// Update table from WebSocket event
  void updateTable(ApiTable apiTable) {
    final updatedTable = _mapApiTableToEntity(apiTable);
    final tables = state.tables.map((table) {
      if (table.id == updatedTable.id) {
        return updatedTable;
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  void updateTableStatus(String tableId, TableStatus status) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(status: status);
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  /// Start table session via API
  /// POST /tables/{tableId}/session
  Future<bool> openTable(
    String tableId, {
    required int guestCount,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    if (_repository == null) {
      // Fallback: update local state only
      _updateTableStatusLocally(tableId, TableStatus.occupied, guestCount);
      return true;
    }

    final tableIdInt = int.tryParse(tableId);
    if (tableIdInt == null) {
      debugPrint('[TablesNotifier] Invalid tableId: $tableId');
      return false;
    }

    debugPrint(
      '[TablesNotifier] Starting session for table $tableId with $guestCount guests',
    );

    final result = await _repository.startSession(
      tableId: tableIdInt,
      guestCount: guestCount,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
    );

    return result.when(
      success: (response, _) {
        debugPrint(
          '[TablesNotifier] Session started: sessionId=${response.sessionId}',
        );
        // Update local state with response data
        final updatedTable = _mapApiTableToEntity(response.table);
        final tables = state.tables.map((table) {
          if (table.id == tableId) {
            return updatedTable;
          }
          return table;
        }).toList();
        state = state.copyWith(tables: tables);
        return true;
      },
      failure: (message, _, __) {
        debugPrint('[TablesNotifier] Failed to start session: $message');
        state = state.copyWith(error: message);
        return false;
      },
    );
  }

  void _updateTableStatusLocally(
    String tableId,
    TableStatus status,
    int? guestCount,
  ) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: status,
          orderStartedAt: DateTime.now(),
          guestCount: guestCount ?? 1,
        );
      }
      return table;
    }).toList();
    state = state.copyWith(tables: tables);
  }

  void closeTable(String tableId) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return RestaurantTable(
          id: table.id,
          name: table.name,
          sectionId: table.sectionId,
          sectionName: table.sectionName,
          status: TableStatus.available,
          capacity: table.capacity,
          sortOrder: table.sortOrder,
        );
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  void lockTable(String tableId, String userId, String userName) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: TableStatus.blocked,
          lockedByUserId: userId,
          lockedByUserName: userName,
        );
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  void unlockTable(String tableId) {
    final tables = state.tables.map((table) {
      if (table.id == tableId && table.status == TableStatus.blocked) {
        return table.copyWith(status: TableStatus.running);
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  void updateRunningTotal(String tableId, double total) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(runningTotal: total);
      }
      return table;
    }).toList();

    state = state.copyWith(tables: tables);
  }

  /// Handle WebSocket table update from stream
  /// Handles multiple payload formats:
  /// Format 1: { tableId, floorId, outletId, event, sessionId, captain } - event-based
  /// Format 2: { tableId, status, session, orderId } - status-based
  /// Format 3: { tableId, tableNumber, oldStatus, newStatus } - legacy
  /// Format 4: { _polling: true, floorId } - polling fallback trigger
  void handleWebSocketTableUpdate(Map<String, dynamic> data) {
    // Check if this is a polling fallback trigger
    if (data['_polling'] == true) {
      debugPrint('[TablesNotifier] Polling fallback: refreshing tables');
      refresh();
      return;
    }

    final tableId = data['tableId']?.toString();
    final event = data['event'] as String?;
    final session = data['session'] as Map<String, dynamic>?;

    // Handle different status field names
    String? newStatus = data['status'] as String?;
    newStatus ??= data['newStatus'] as String?;

    // Map event type to status if no direct status provided
    if (newStatus == null && event != null) {
      newStatus = _mapEventToStatus(event);
    }

    debugPrint(
      '[TablesNotifier] handleWebSocketTableUpdate: tableId=$tableId, event=$event, status=$newStatus',
    );

    if (tableId == null) {
      debugPrint('[TablesNotifier] Invalid data: tableId is null');
      return;
    }

    // If still no status, skip update
    if (newStatus == null) {
      debugPrint('[TablesNotifier] No status could be determined, skipping');
      return;
    }

    final status = _mapApiStatusToTableStatus(newStatus);
    bool found = false;

    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        found = true;
        debugPrint(
          '[TablesNotifier] Updating table ${table.name} from ${table.status} to $status',
        );

        // Build updated table with all available data
        // Extract running total from various possible fields
        final orderTotal =
            (data['orderTotal'] as num?)?.toDouble() ??
            (data['order_total'] as num?)?.toDouble() ??
            (data['runningTotal'] as num?)?.toDouble();

        return table.copyWith(
          status: status,
          guestCount:
              session?['guestCount'] as int? ?? session?['guest_count'] as int?,
          orderStartedAt:
              (event == 'session_started' || status == TableStatus.occupied)
              ? DateTime.now()
              : table.orderStartedAt,
          runningTotal: orderTotal ?? table.runningTotal,
          lockedByUserId:
              (data['captainId'] ?? data['captain_id'])?.toString() ??
              table.lockedByUserId,
          lockedByUserName:
              (data['captainName'] as String?) ??
              (data['captain_name'] as String?) ??
              table.lockedByUserName,
        );
      }
      return table;
    }).toList();

    if (!found) {
      debugPrint(
        '[TablesNotifier] Table $tableId not found in current state (${state.tables.length} tables)',
      );
    } else {
      state = state.copyWith(tables: tables);
    }
  }

  /// Map WebSocket event type to table status
  /// Only handles table:updated events
  String? _mapEventToStatus(String event) {
    switch (event.toLowerCase()) {
      case 'session_started':
        return 'occupied';
      case 'session_ended':
        return 'available';
      case 'tables_merged':
        return 'occupied';
      case 'tables_unmerged':
        return 'available';
      case 'status_changed':
        // status_changed event should have a separate status field
        return null;
      default:
        debugPrint('[TablesNotifier] Unknown table:updated event: $event');
        return null;
    }
  }

  /// Map order:updated type to table status
  String? _mapOrderTypeToStatus(String type) {
    switch (type.toLowerCase()) {
      case 'order:created':
      case 'order:items_added':
      case 'order:kot_sent':
      case 'order:item_ready':
      case 'order:all_ready':
      case 'order:all_served':
        return 'running';
      case 'order:billed':
        return 'billing';
      case 'order:payment_received':
      case 'order:cancelled':
      case 'order:transferred':
        return 'available';
      default:
        debugPrint('[TablesNotifier] Unknown order type: $type');
        return null;
    }
  }

  /// Map bill:status to table status
  String? _mapBillStatusToTableStatus(String billStatus) {
    switch (billStatus.toLowerCase()) {
      case 'pending':
        return 'billing';
      case 'paid':
        return 'available';
      default:
        debugPrint('[TablesNotifier] Unknown bill status: $billStatus');
        return null;
    }
  }

  /// Handle order:updated WebSocket event
  /// Payload: { type, outletId, orderId, tableId, status, orderTotal, ... }
  void handleOrderUpdate(Map<String, dynamic> data) {
    final tableId = data['tableId']?.toString();
    final type = data['type'] as String?;

    debugPrint(
      '[TablesNotifier] handleOrderUpdate: tableId=$tableId, type=$type',
    );

    if (tableId == null || type == null) {
      debugPrint(
        '[TablesNotifier] Invalid order update: missing tableId or type',
      );
      return;
    }

    final status = _mapOrderTypeToStatus(type);
    if (status == null) {
      return;
    }

    // Extract running total from order update
    final orderTotal =
        (data['orderTotal'] as num?)?.toDouble() ??
        (data['order_total'] as num?)?.toDouble() ??
        (data['total'] as num?)?.toDouble() ??
        (data['grandTotal'] as num?)?.toDouble();

    final tableStatus = _mapApiStatusToTableStatus(status);
    bool found = false;

    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        found = true;
        debugPrint(
          '[TablesNotifier] Updating table ${table.name} from ${table.status} to $tableStatus (order: $type, total: $orderTotal)',
        );
        return table.copyWith(
          status: tableStatus,
          runningTotal: orderTotal ?? table.runningTotal,
        );
      }
      return table;
    }).toList();

    if (!found) {
      debugPrint('[TablesNotifier] Table $tableId not found in state');
    } else {
      state = state.copyWith(tables: tables);
    }
  }

  /// Handle bill:status WebSocket event
  /// Payload: { outletId, orderId, tableId, status, grandTotal }
  void handleBillStatusUpdate(Map<String, dynamic> data) {
    final tableId = data['tableId']?.toString();
    final billStatus = data['status'] as String?;

    debugPrint(
      '[TablesNotifier] handleBillStatusUpdate: tableId=$tableId, billStatus=$billStatus',
    );

    if (tableId == null || billStatus == null) {
      debugPrint(
        '[TablesNotifier] Invalid bill status: missing tableId or status',
      );
      return;
    }

    final status = _mapBillStatusToTableStatus(billStatus);
    if (status == null) {
      return;
    }

    final tableStatus = _mapApiStatusToTableStatus(status);
    bool found = false;

    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        found = true;
        debugPrint(
          '[TablesNotifier] Updating table ${table.name} from ${table.status} to $tableStatus (bill: $billStatus)',
        );
        // Extract grand total from bill event
        final grandTotal =
            (data['grandTotal'] as num?)?.toDouble() ??
            (data['grand_total'] as num?)?.toDouble();
        return table.copyWith(
          status: tableStatus,
          runningTotal: grandTotal ?? table.runningTotal,
        );
      }
      return table;
    }).toList();

    if (!found) {
      debugPrint('[TablesNotifier] Table $tableId not found in state');
    } else {
      state = state.copyWith(tables: tables);
    }
  }

  /// Handle table:updated WebSocket event (legacy format)
  /// Payload: { tableId, tableNumber, oldStatus, newStatus, changedBy, timestamp }
  void handleTableUpdatedEvent(Map<String, dynamic> data) {
    // Delegate to new handler
    handleWebSocketTableUpdate(data);
  }

  // Handle WebSocket event (legacy)
  void handleTableEvent(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'TABLE_STATUS_UPDATED':
        final tableId = data['tableId'] as String;
        final status = TableStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => TableStatus.available,
        );
        updateTableStatus(tableId, status);
        break;
      case 'TABLE_CLOSED':
        final tableId = data['tableId'] as String;
        closeTable(tableId);
        break;
    }
  }

  Future<void> refresh() async {
    // Reload tables from API using current floor
    final currentFloor = state.currentFloorId;
    if (currentFloor != null) {
      await loadTablesByFloorDetails(currentFloor);
    }
  }
}
