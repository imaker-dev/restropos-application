import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/menu_item.dart';
import '../../data/dummy_data/dummy_menu.dart';

// Categories provider
final categoriesProvider = Provider<List<MenuCategory>>((ref) {
  return DummyMenu.categories;
});

// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) {
  return DummyMenu.categories.first.id;
});

// All menu items provider
final menuItemsProvider = Provider<List<MenuItem>>((ref) {
  return DummyMenu.items;
});

// Filtered items by category
final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final items = ref.watch(menuItemsProvider);
  
  if (selectedCategory == null) {
    return items;
  }
  
  if (selectedCategory == 'cat_favorites') {
    return items.where((i) => i.isFavorite).toList();
  }
  
  return items.where((i) => i.categoryId == selectedCategory).toList();
});

// Search query provider
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

// Searched items provider
final searchedMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final query = ref.watch(menuSearchQueryProvider);
  final items = ref.watch(filteredMenuItemsProvider);
  
  if (query.isEmpty) {
    return items;
  }
  
  final lowerQuery = query.toLowerCase();
  return items.where((i) =>
    i.name.toLowerCase().contains(lowerQuery) ||
    i.shortCode.toLowerCase().contains(lowerQuery)
  ).toList();
});

// Favorite items provider
final favoriteItemsProvider = Provider<List<MenuItem>>((ref) {
  return ref.watch(menuItemsProvider).where((i) => i.isFavorite).toList();
});

// Single item provider for optimized rebuilds
final menuItemProvider = Provider.family<MenuItem?, String>((ref, itemId) {
  final items = ref.watch(menuItemsProvider);
  try {
    return items.firstWhere((i) => i.id == itemId);
  } catch (_) {
    return null;
  }
});
