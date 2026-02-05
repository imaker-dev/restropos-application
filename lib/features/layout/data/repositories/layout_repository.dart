import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/layout_models.dart';
import '../../../tables/data/models/table_details_model.dart';

/// Repository for Layout operations (Floors, Sections, Tables)
class LayoutRepository {
  final ApiService _api;

  LayoutRepository(this._api);

  /// Get all floors for an outlet
  Future<ApiResult<List<Floor>>> getFloors(int outletId) async {
    return _api.getList(ApiEndpoints.floors(outletId), parser: Floor.fromJson);
  }

  /// Get all sections for an outlet
  Future<ApiResult<List<Section>>> getSections(int outletId) async {
    return _api.getList(
      ApiEndpoints.sections(outletId),
      parser: Section.fromJson,
    );
  }

  /// Get floor details with tables
  Future<ApiResult<Floor>> getFloorDetails(int floorId) async {
    return _api.get(
      ApiEndpoints.floorDetails(floorId),
      parser: (json) => Floor.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get section by ID
  Future<ApiResult<Section>> getSectionById(int sectionId) async {
    return _api.get(
      ApiEndpoints.sectionById(sectionId),
      parser: (json) => Section.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get tables by floor
  Future<ApiResult<List<ApiTable>>> getTablesByFloor(int floorId) async {
    return _api.getList(
      ApiEndpoints.tablesByFloor(floorId),
      parser: ApiTable.fromJson,
    );
  }

  /// Get tables by outlet
  Future<ApiResult<List<ApiTable>>> getTablesByOutlet(int outletId) async {
    return _api.getList(
      ApiEndpoints.tablesByOutlet(outletId),
      parser: ApiTable.fromJson,
    );
  }

  /// Get realtime table status
  Future<ApiResult<List<ApiTable>>> getRealtimeTableStatus(int outletId) async {
    return _api.getList(
      ApiEndpoints.tablesRealtime(outletId),
      parser: ApiTable.fromJson,
    );
  }

  /// Get table by ID
  Future<ApiResult<ApiTable>> getTableById(int tableId) async {
    return _api.get(
      ApiEndpoints.tableById(tableId),
      parser: (json) => ApiTable.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get detailed table information (session, order, items, KOTs, etc.)
  Future<ApiResult<TableDetailsResponse>> getTableDetails(int tableId) async {
    return _api.get(
      ApiEndpoints.tableById(tableId),
      parser: (json) => TableDetailsResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Start table session
  Future<ApiResult<TableSession>> startSession({
    required int tableId,
    required int covers,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    final request = StartSessionRequest(
      covers: covers,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );
    return _api.post(
      ApiEndpoints.tableSession(tableId),
      data: request.toJson(),
      parser: (json) => TableSession.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get current session for a table
  Future<ApiResult<TableSession>> getCurrentSession(int tableId) async {
    return _api.get(
      ApiEndpoints.tableSession(tableId),
      parser: (json) => TableSession.fromJson(json as Map<String, dynamic>),
    );
  }

  /// End table session
  Future<ApiResult<bool>> endSession(int tableId) async {
    return _api.deleteVoid(ApiEndpoints.tableSession(tableId));
  }

  /// Merge tables
  Future<ApiResult<ApiTable>> mergeTables({
    required int primaryTableId,
    required List<int> tableIds,
  }) async {
    final request = MergeTablesRequest(tableIds: tableIds);
    return _api.post(
      ApiEndpoints.tableMerge(primaryTableId),
      data: request.toJson(),
      parser: (json) => ApiTable.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get merged tables
  Future<ApiResult<List<ApiTable>>> getMergedTables(int tableId) async {
    return _api.getList(
      ApiEndpoints.tableMerged(tableId),
      parser: ApiTable.fromJson,
    );
  }

  /// Unmerge tables
  Future<ApiResult<bool>> unmergeTables(int tableId) async {
    return _api.deleteVoid(ApiEndpoints.tableMerge(tableId));
  }
}

/// Provider for LayoutRepository
final layoutRepositoryProvider = Provider<LayoutRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return LayoutRepository(api);
});
