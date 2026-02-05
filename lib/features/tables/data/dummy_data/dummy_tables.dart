import '../../domain/entities/table_entity.dart';

class DummyTables {
  DummyTables._();

  static final List<TableSection> sections = [
    const TableSection(id: 'section_ac', name: 'AC', floorId: 'floor_1', sortOrder: 0),
    const TableSection(id: 'section_garden', name: 'Garden', floorId: 'floor_1', sortOrder: 1),
    const TableSection(id: 'section_nonac', name: 'Non AC', floorId: 'floor_1', sortOrder: 2),
    const TableSection(id: 'section_rooftop', name: 'Rooftop', floorId: 'floor_1', sortOrder: 3),
  ];

  static List<RestaurantTable> generateTables() {
    final List<RestaurantTable> tables = [];

    // AC Tables (AC1 - AC20)
    for (int i = 1; i <= 20; i++) {
      tables.add(RestaurantTable(
        id: 'table_ac_$i',
        name: 'AC$i',
        sectionId: 'section_ac',
        sectionName: 'AC',
        status: _getRandomStatus(i),
        capacity: i % 3 == 0 ? 6 : 4,
        sortOrder: i,
        currentOrderId: i == 4 ? 'order_001' : null,
        runningTotal: i == 4 ? 1157.0 : null,
        orderStartedAt: i == 4 ? DateTime.now().subtract(const Duration(minutes: 30)) : null,
      ));
    }

    // Garden Tables (G21 - G40)
    for (int i = 21; i <= 40; i++) {
      tables.add(RestaurantTable(
        id: 'table_g_$i',
        name: 'G$i',
        sectionId: 'section_garden',
        sectionName: 'Garden',
        status: TableStatus.available,
        capacity: 4,
        sortOrder: i,
      ));
    }

    // Non AC Tables (NAC41 - NAC50)
    for (int i = 41; i <= 50; i++) {
      tables.add(RestaurantTable(
        id: 'table_nac_$i',
        name: 'NAC$i',
        sectionId: 'section_nonac',
        sectionName: 'Non AC',
        status: TableStatus.available,
        capacity: 4,
        sortOrder: i,
      ));
    }

    // Rooftop Tables (RF1 - RF10)
    for (int i = 1; i <= 10; i++) {
      tables.add(RestaurantTable(
        id: 'table_rf_$i',
        name: 'RF$i',
        sectionId: 'section_rooftop',
        sectionName: 'Rooftop',
        status: TableStatus.available,
        capacity: i % 2 == 0 ? 6 : 4,
        sortOrder: 50 + i,
      ));
    }

    return tables;
  }

  static TableStatus _getRandomStatus(int index) {
    if (index == 4) return TableStatus.occupied;
    if (index == 7) return TableStatus.running;
    if (index == 12) return TableStatus.billing;
    if (index == 15) return TableStatus.reserved;
    return TableStatus.available;
  }

  static List<RestaurantTable> tables = generateTables();

  static List<RestaurantTable> getTablesBySection(String sectionId) {
    return tables.where((t) => t.sectionId == sectionId).toList();
  }

  static RestaurantTable? getTableById(String tableId) {
    try {
      return tables.firstWhere((t) => t.id == tableId);
    } catch (_) {
      return null;
    }
  }

  static void updateTableStatus(String tableId, TableStatus status) {
    final index = tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      tables[index] = tables[index].copyWith(status: status);
    }
  }
}
