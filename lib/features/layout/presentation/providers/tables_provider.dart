import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/layout_models.dart';
import '../../data/repositories/layout_repository.dart';

// State classes
class TablesState {
  final bool isLoading;
  final List<ApiTable> tables;
  final List<Floor> floors;
  final List<Section> sections;
  final String? error;
  final int? selectedFloorId;
  final int? selectedSectionId;

  const TablesState({
    this.isLoading = false,
    this.tables = const [],
    this.floors = const [],
    this.sections = const [],
    this.error,
    this.selectedFloorId,
    this.selectedSectionId,
  });

  TablesState copyWith({
    bool? isLoading,
    List<ApiTable>? tables,
    List<Floor>? floors,
    List<Section>? sections,
    String? error,
    int? selectedFloorId,
    int? selectedSectionId,
  }) {
    return TablesState(
      isLoading: isLoading ?? this.isLoading,
      tables: tables ?? this.tables,
      floors: floors ?? this.floors,
      sections: sections ?? this.sections,
      error: error,
      selectedFloorId: selectedFloorId ?? this.selectedFloorId,
      selectedSectionId: selectedSectionId ?? this.selectedSectionId,
    );
  }

  List<ApiTable> get filteredTables {
    var filtered = tables;
    if (selectedFloorId != null) {
      filtered = filtered.where((t) => t.floorId == selectedFloorId).toList();
    }
    if (selectedSectionId != null) {
      filtered = filtered
          .where((t) => t.sectionId == selectedSectionId)
          .toList();
    }
    return filtered;
  }

  int get availableCount => tables.where((t) => t.isAvailable).length;
  int get occupiedCount => tables.where((t) => t.isOccupied).length;
  int get reservedCount => tables.where((t) => t.isReserved).length;
}

class TablesNotifier extends StateNotifier<TablesState> {
  final LayoutRepository _repository;
  final Ref _ref;

  TablesNotifier(this._repository, this._ref) : super(const TablesState());

  int get _outletId => _ref.read(outletIdProvider);

  Future<void> loadTables() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getRealtimeTableStatus(_outletId);

    result.when(
      success: (tables, _) {
        state = state.copyWith(isLoading: false, tables: tables);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> loadFloors() async {
    final result = await _repository.getFloors(_outletId);

    result.when(
      success: (floors, _) {
        state = state.copyWith(floors: floors);
      },
      failure: (_, __, ___) {},
    );
  }

  Future<void> loadSections() async {
    final result = await _repository.getSections(_outletId);

    result.when(
      success: (sections, _) {
        state = state.copyWith(sections: sections);
      },
      failure: (_, __, ___) {},
    );
  }

  Future<void> refreshAll() async {
    await Future.wait([loadTables(), loadFloors(), loadSections()]);
  }

  void selectFloor(int? floorId) {
    state = state.copyWith(selectedFloorId: floorId);
  }

  void selectSection(int? sectionId) {
    state = state.copyWith(selectedSectionId: sectionId);
  }

  Future<ApiResult<StartSessionResponse>> startSession({
    required int tableId,
    required int guestCount,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    final result = await _repository.startSession(
      tableId: tableId,
      guestCount: guestCount,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
    );

    // Refresh tables on success
    result.whenOrNull(success: (_, __) => loadTables());

    return result;
  }

  Future<ApiResult<bool>> endSession(int tableId) async {
    final result = await _repository.endSession(tableId);

    // Refresh tables on success
    result.whenOrNull(success: (_, __) => loadTables());

    return result;
  }

  Future<ApiResult<ApiTable>> mergeTables({
    required int primaryTableId,
    required List<int> tableIds,
  }) async {
    final result = await _repository.mergeTables(
      primaryTableId: primaryTableId,
      tableIds: tableIds,
    );

    // Refresh tables on success
    result.whenOrNull(success: (_, __) => loadTables());

    return result;
  }

  Future<ApiResult<bool>> unmergeTables(int tableId) async {
    final result = await _repository.unmergeTables(tableId);

    // Refresh tables on success
    result.whenOrNull(success: (_, __) => loadTables());

    return result;
  }

  // Update a single table from WebSocket event
  void updateTable(ApiTable table) {
    final updatedTables = state.tables.map((t) {
      return t.id == table.id ? table : t;
    }).toList();
    state = state.copyWith(tables: updatedTables);
  }
}

// Providers
final tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((
  ref,
) {
  final repository = ref.watch(layoutRepositoryProvider);
  return TablesNotifier(repository, ref);
});

final tableByIdProvider = Provider.family<ApiTable?, int>((ref, tableId) {
  final tables = ref.watch(tablesProvider).tables;
  try {
    return tables.firstWhere((t) => t.id == tableId);
  } catch (_) {
    return null;
  }
});

final availableTablesProvider = Provider<List<ApiTable>>((ref) {
  return ref.watch(tablesProvider).tables.where((t) => t.isAvailable).toList();
});

final occupiedTablesProvider = Provider<List<ApiTable>>((ref) {
  return ref.watch(tablesProvider).tables.where((t) => t.isOccupied).toList();
});
