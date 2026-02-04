import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/menu_models.dart';
import '../../data/repositories/menu_repository.dart';

// Menu State
class MenuState {
  final bool isLoading;
  final List<ApiCategory> categories;
  final List<ApiMenuItem> items;
  final String? error;
  final int? selectedCategoryId;

  const MenuState({
    this.isLoading = false,
    this.categories = const [],
    this.items = const [],
    this.error,
    this.selectedCategoryId,
  });

  MenuState copyWith({
    bool? isLoading,
    List<ApiCategory>? categories,
    List<ApiMenuItem>? items,
    String? error,
    int? selectedCategoryId,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      error: error,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }

  List<ApiMenuItem> get filteredItems {
    if (selectedCategoryId == null) return items;
    return items.where((i) => i.categoryId == selectedCategoryId).toList();
  }

  List<ApiMenuItem> get availableItems =>
      items.where((i) => i.isAvailable).toList();
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repository;
  final Ref _ref;

  MenuNotifier(this._repository, this._ref) : super(const MenuState());

  int get _outletId => _ref.read(outletIdProvider);

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getCaptainMenu(_outletId);

    result.when(
      success: (menu, _) {
        // Debug: Log the loaded menu data
        debugPrint(
          'Menu loaded: ${menu.categories.length} categories, ${menu.items.length} items',
        );
        for (final cat in menu.categories) {
          debugPrint(
            'Category: ${cat.id} - ${cat.name} (${cat.items?.length ?? 0} items)',
          );
        }

        // Debug: Log items with their categoryId
        final items = menu.items;
        for (final item in items.take(5)) {
          debugPrint(
            'Item: ${item.id} - ${item.name} (categoryId: ${item.categoryId})',
          );
        }

        state = state.copyWith(
          isLoading: false,
          categories: menu.categories,
          items: items,
          selectedCategoryId: menu.categories.isNotEmpty
              ? menu.categories.first.id
              : null,
        );
      },
      failure: (message, _, __) {
        debugPrint('Menu load failed: $message');
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> loadCategories() async {
    final result = await _repository.getCategories(_outletId);

    result.whenOrNull(
      success: (categories, _) {
        state = state.copyWith(categories: categories);
      },
    );
  }

  Future<void> loadItems() async {
    final result = await _repository.getMenuItems(_outletId);

    result.whenOrNull(
      success: (items, _) {
        state = state.copyWith(items: items);
      },
    );
  }

  Future<void> loadItemsByCategory(int categoryId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getItemsByCategory(categoryId);

    result.when(
      success: (items, _) {
        state = state.copyWith(isLoading: false, items: items);
      },
      failure: (message, _, __) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  void selectCategory(int? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Future<List<ApiMenuItem>> searchItems(String query) async {
    if (query.isEmpty) return state.items;

    final result = await _repository.searchItems(_outletId, query);
    return result.when(
      success: (items, _) => items,
      failure: (_, __, ___) => <ApiMenuItem>[],
    );
  }
}

// Providers
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repository, ref);
});

// Selected category provider
final selectedCategoryProvider = StateProvider<int?>((ref) {
  return ref.watch(menuProvider).selectedCategoryId;
});

// Search query provider
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered items by category
final filteredMenuItemsProvider = Provider<List<ApiMenuItem>>((ref) {
  final menuState = ref.watch(menuProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(menuSearchQueryProvider);

  // Filter by selected category
  var items = menuState.items;
  if (selectedCategoryId != null) {
    items = items.where((i) => i.categoryId == selectedCategoryId).toList();
  }

  // Filter by search query
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    items = items
        .where(
          (i) =>
              i.name.toLowerCase().contains(lowerQuery) ||
              (i.shortCode?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }

  return items;
});

// Categories provider
final categoriesProvider = Provider<List<ApiCategory>>((ref) {
  return ref.watch(menuProvider).categories;
});

// Single item provider
final menuItemProvider = Provider.family<ApiMenuItem?, int>((ref, itemId) {
  final items = ref.watch(menuProvider).items;
  try {
    return items.firstWhere((i) => i.id == itemId);
  } catch (_) {
    return null;
  }
});

// Featured items provider
final featuredItemsProvider = FutureProvider<List<ApiMenuItem>>((ref) async {
  final repository = ref.watch(menuRepositoryProvider);
  final outletId = ref.watch(outletIdProvider);

  final result = await repository.getFeaturedItems(outletId);
  return result.when(
    success: (items, _) => items,
    failure: (_, __, ___) => <ApiMenuItem>[],
  );
});

// Legacy providers for backward compatibility
final menuItemsProvider = Provider<List<ApiMenuItem>>((ref) {
  return ref.watch(menuProvider).items;
});

final searchedMenuItemsProvider = Provider<List<ApiMenuItem>>((ref) {
  return ref.watch(filteredMenuItemsProvider);
});
