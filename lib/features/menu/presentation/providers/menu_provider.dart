import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/menu_models.dart';
import '../../data/repositories/menu_repository.dart';

// Menu State
/// Sentinel value to explicitly clear selectedCategoryId to null
const int _clearCategoryId = -1;

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

  /// Use [_clearCategoryId] (-1) to explicitly set selectedCategoryId to null.
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
      selectedCategoryId: selectedCategoryId == _clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
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

  Future<void> loadMenu({String? filter, bool silent = false}) async {
    // silent=true keeps old items visible during filter switch (no loader flash)
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repository.getCaptainMenu(_outletId, filter: filter);

    result.when(
      success: (menu, _) {
        debugPrint(
          'Menu loaded: ${menu.categories.length} categories, ${menu.items.length} items (filter: $filter)',
        );

        final items = menu.items;
        state = state.copyWith(
          isLoading: false,
          categories: menu.categories,
          items: items,
          // Default to "All" (null) so all items are shown initially
          selectedCategoryId: _clearCategoryId,
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
    state = state.copyWith(selectedCategoryId: categoryId ?? _clearCategoryId);
  }

  Future<MenuSearchResponse?> searchMenuItems(
    String query, {
    String? filter,
  }) async {
    if (query.isEmpty) return null;

    final result = await _repository.searchMenuItems(
      _outletId,
      query,
      filter: filter,
    );
    return result.when(
      success: (response, _) => response,
      failure: (_, __, ___) => null,
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

// Menu type filter provider: null = all, 'veg', 'non_veg', 'liquor'
final menuFilterProvider = StateProvider<String?>((ref) => null);

// Search query provider (local text input)
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

// API search state
class MenuSearchState {
  final bool isSearching;
  final List<ApiMenuItem> results;
  final String? error;

  const MenuSearchState({
    this.isSearching = false,
    this.results = const [],
    this.error,
  });

  MenuSearchState copyWith({
    bool? isSearching,
    List<ApiMenuItem>? results,
    String? error,
  }) {
    return MenuSearchState(
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      error: error,
    );
  }
}

class MenuSearchNotifier extends StateNotifier<MenuSearchState> {
  final MenuRepository _repository;
  final Ref _ref;
  Timer? _debounce;

  MenuSearchNotifier(this._repository, this._ref)
    : super(const MenuSearchState());

  int get _outletId => _ref.read(outletIdProvider);

  void search(String query, {String? filter}) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = const MenuSearchState();
      return;
    }

    state = state.copyWith(isSearching: true);

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final result = await _repository.searchMenuItems(
        _outletId,
        query.trim(),
        filter: filter,
      );

      result.when(
        success: (response, _) {
          state = MenuSearchState(
            isSearching: false,
            results: response.allItems,
          );
        },
        failure: (message, _, __) {
          state = MenuSearchState(isSearching: false, error: message);
        },
      );
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const MenuSearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final menuSearchProvider =
    StateNotifierProvider<MenuSearchNotifier, MenuSearchState>((ref) {
      final repository = ref.watch(menuRepositoryProvider);
      return MenuSearchNotifier(repository, ref);
    });

// Filtered items by category (used when NOT searching)
final filteredMenuItemsProvider = Provider<List<ApiMenuItem>>((ref) {
  final menuState = ref.watch(menuProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);

  // Filter by selected category
  var items = menuState.items;
  if (selectedCategoryId != null) {
    items = items.where((i) => i.categoryId == selectedCategoryId).toList();
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
  final query = ref.watch(menuSearchQueryProvider);
  final searchState = ref.watch(menuSearchProvider);

  // If there's an active search query, use API search results
  if (query.trim().isNotEmpty) {
    return searchState.results;
  }

  // Otherwise, use category-filtered menu items
  return ref.watch(filteredMenuItemsProvider);
});
