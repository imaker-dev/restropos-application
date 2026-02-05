import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/menu_models.dart';

/// Repository for Menu operations (Categories & Items)
class MenuRepository {
  final ApiService _api;

  MenuRepository(this._api);

  /// Get all categories for an outlet
  Future<ApiResult<List<ApiCategory>>> getCategories(int outletId) async {
    return _api.getList(
      ApiEndpoints.categories(outletId),
      parser: ApiCategory.fromJson,
    );
  }

  /// Get category tree for an outlet
  Future<ApiResult<List<ApiCategory>>> getCategoryTree(int outletId) async {
    return _api.getList(
      ApiEndpoints.categoryTree(outletId),
      parser: ApiCategory.fromJson,
    );
  }

  /// Get category by ID
  Future<ApiResult<ApiCategory>> getCategoryById(int categoryId) async {
    return _api.get(
      ApiEndpoints.categoryById(categoryId),
      parser: (json) => ApiCategory.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get captain menu (categories + items optimized for captain view)
  Future<ApiResult<CaptainMenu>> getCaptainMenu(int outletId) async {
    return _api.get(
      ApiEndpoints.captainMenu(outletId),
      parser: (json) => CaptainMenu.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get all menu items for an outlet
  Future<ApiResult<List<ApiMenuItem>>> getMenuItems(int outletId) async {
    return _api.getList(
      ApiEndpoints.menuItems(outletId),
      parser: ApiMenuItem.fromJson,
    );
  }

  /// Get items by category
  Future<ApiResult<List<ApiMenuItem>>> getItemsByCategory(int categoryId) async {
    return _api.getList(
      ApiEndpoints.itemsByCategory(categoryId),
      parser: ApiMenuItem.fromJson,
    );
  }

  /// Get item by ID
  Future<ApiResult<ApiMenuItem>> getItemById(int itemId) async {
    return _api.get(
      ApiEndpoints.itemById(itemId),
      parser: (json) => ApiMenuItem.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get item details with variants and addons
  Future<ApiResult<ApiMenuItem>> getItemDetails(int itemId) async {
    return _api.get(
      ApiEndpoints.itemDetails(itemId),
      parser: (json) => ApiMenuItem.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Search items
  Future<ApiResult<List<ApiMenuItem>>> searchItems(int outletId, String query) async {
    return _api.getList(
      ApiEndpoints.searchItems(outletId, query),
      parser: ApiMenuItem.fromJson,
    );
  }

  /// Get featured items
  Future<ApiResult<List<ApiMenuItem>>> getFeaturedItems(int outletId) async {
    return _api.getList(
      ApiEndpoints.featuredItems(outletId),
      parser: ApiMenuItem.fromJson,
    );
  }

  /// Calculate item total
  Future<ApiResult<CalculateItemResponse>> calculateItemTotal({
    required int itemId,
    required int quantity,
    int? variantId,
    List<int>? addonIds,
  }) async {
    final request = CalculateItemRequest(
      itemId: itemId,
      quantity: quantity,
      variantId: variantId,
      addonIds: addonIds,
    );
    return _api.post(
      ApiEndpoints.calculateItem,
      data: request.toJson(),
      parser: (json) => CalculateItemResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Provider for MenuRepository
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return MenuRepository(api);
});
