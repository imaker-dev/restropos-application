import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/table_entity.dart';
import '../../data/dummy_data/dummy_tables.dart';

// Sections provider
final sectionsProvider = Provider<List<TableSection>>((ref) {
  return DummyTables.sections;
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
final tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  return TablesNotifier();
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
final tablesGroupedBySectionProvider = Provider<Map<String, List<RestaurantTable>>>((ref) {
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

  TablesState({
    required this.tables,
    this.isLoading = false,
    this.error,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  TablesState copyWith({
    List<RestaurantTable>? tables,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  factory TablesState.initial() => TablesState(
    tables: DummyTables.tables,
  );
}

class TablesNotifier extends StateNotifier<TablesState> {
  TablesNotifier() : super(TablesState.initial());

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
          status: TableStatus.blank,
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
          status: TableStatus.locked,
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
      if (table.id == tableId && table.status == TableStatus.locked) {
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
          orElse: () => TableStatus.blank,
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
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    state = state.copyWith(
      tables: DummyTables.generateTables(),
      isLoading: false,
    );
  }
}
