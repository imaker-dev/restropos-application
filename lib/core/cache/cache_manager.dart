import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

class CacheManager {
  static const String _generalBox = 'general_cache';
  static const String _menuBox = 'menu_cache';
  static const String _tablesBox = 'tables_cache';
  static const String _ordersBox = 'orders_cache';
  static const String _userBox = 'user_cache';

  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheExpiry = {};

  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_generalBox),
      Hive.openBox(_menuBox),
      Hive.openBox(_tablesBox),
      Hive.openBox(_ordersBox),
      Hive.openBox(_userBox),
    ]);
  }

  // Memory Cache Operations
  T? getMemory<T>(String key) {
    if (_cacheExpiry.containsKey(key)) {
      if (DateTime.now().isAfter(_cacheExpiry[key]!)) {
        _memoryCache.remove(key);
        _cacheExpiry.remove(key);
        return null;
      }
    }
    return _memoryCache[key] as T?;
  }

  void setMemory<T>(String key, T value, {Duration? expiry}) {
    _memoryCache[key] = value;
    if (expiry != null) {
      _cacheExpiry[key] = DateTime.now().add(expiry);
    }
  }

  void removeMemory(String key) {
    _memoryCache.remove(key);
    _cacheExpiry.remove(key);
  }

  void clearMemory() {
    _memoryCache.clear();
    _cacheExpiry.clear();
  }

  // Persistent Cache Operations
  Future<T?> get<T>(String boxName, String key) async {
    final box = Hive.box(boxName);
    return box.get(key) as T?;
  }

  Future<void> set<T>(String boxName, String key, T value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  Future<void> remove(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAll() async {
    clearMemory();
    await Future.wait([
      clearBox(_generalBox),
      clearBox(_menuBox),
      clearBox(_tablesBox),
      clearBox(_ordersBox),
      clearBox(_userBox),
    ]);
  }

  // Convenience methods for specific cache types
  Future<void> cacheMenu(Map<String, dynamic> menu) async {
    await set(_menuBox, 'menu_data', menu);
    setMemory('menu_data', menu);
  }

  Future<Map<String, dynamic>?> getMenu() async {
    // Try memory cache first
    final memoryMenu = getMemory<Map<String, dynamic>>('menu_data');
    if (memoryMenu != null) return memoryMenu;

    // Fall back to persistent cache
    return await get<Map<String, dynamic>>(_menuBox, 'menu_data');
  }

  Future<void> cacheTables(List<Map<String, dynamic>> tables) async {
    await set(_tablesBox, 'tables_data', tables);
    setMemory('tables_data', tables);
  }

  Future<List<Map<String, dynamic>>?> getTables() async {
    final memoryTables = getMemory<List<Map<String, dynamic>>>('tables_data');
    if (memoryTables != null) return memoryTables;

    return await get<List<Map<String, dynamic>>>(_tablesBox, 'tables_data');
  }

  Future<void> cacheUser(Map<String, dynamic> user) async {
    await set(_userBox, 'current_user', user);
    setMemory('current_user', user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final memoryUser = getMemory<Map<String, dynamic>>('current_user');
    if (memoryUser != null) return memoryUser;

    return await get<Map<String, dynamic>>(_userBox, 'current_user');
  }

  // Event-based cache invalidation
  void invalidateByEvent(String event) {
    switch (event) {
      case 'MENU_UPDATED':
      case 'PRICE_UPDATED':
        removeMemory('menu_data');
        break;
      case 'TABLE_STATUS_UPDATED':
      case 'TABLE_CLOSED':
      case 'TABLE_TRANSFERRED':
      case 'TABLE_MERGED':
      case 'TABLE_SPLIT':
        removeMemory('tables_data');
        break;
    }
  }
}
