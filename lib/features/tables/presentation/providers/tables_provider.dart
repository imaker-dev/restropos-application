import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return TablesNotifier(repository);
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

  TablesNotifier([this._repository]) : super(TablesState.initial());

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
      runningTotal: apiTable.orderTotal,
      orderStartedAt: apiTable.sessionStart,
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

  void openTable(String tableId, {int? guestCount}) {
    final tables = state.tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: TableStatus.running,
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

  // Handle WebSocket event
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
