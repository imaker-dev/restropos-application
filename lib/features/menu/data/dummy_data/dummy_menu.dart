import '../../domain/entities/menu_item.dart';

class DummyMenu {
  DummyMenu._();

  static final List<MenuCategory> categories = [
    const MenuCategory(id: 'cat_beverages', name: 'Beverages', sortOrder: 0),
    const MenuCategory(id: 'cat_favorites', name: 'Favorite Items', sortOrder: 1),
    const MenuCategory(id: 'cat_indian', name: 'Indian', sortOrder: 2),
    const MenuCategory(id: 'cat_mocktails', name: 'Mocktails', sortOrder: 3),
    const MenuCategory(id: 'cat_cocktails', name: 'Cocktails', sortOrder: 4),
    const MenuCategory(id: 'cat_softdrinks', name: 'Soft Drinks', sortOrder: 5),
    const MenuCategory(id: 'cat_starters', name: 'Starters', sortOrder: 6),
    const MenuCategory(id: 'cat_maincourse', name: 'Main Course', sortOrder: 7),
    const MenuCategory(id: 'cat_desserts', name: 'Desserts', sortOrder: 8),
  ];

  static final List<MenuItem> items = [
    // Beverages
    const MenuItem(
      id: 'item_chaas',
      name: 'Chaas',
      shortCode: 'CHS',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 40.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_chai',
      name: 'Chai',
      shortCode: 'CHI',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 30.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_coffee',
      name: 'Coffee',
      shortCode: 'COF',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 50.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_limbu_paani',
      name: 'Limbu Paani',
      shortCode: 'LMP',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 35.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_soda',
      name: 'Soda',
      shortCode: 'SOD',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 25.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_thandai',
      name: 'Thandai',
      shortCode: 'THD',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 80.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_virgin_pina_colada',
      name: 'Virgin Pina Colada',
      shortCode: 'VPC',
      categoryId: 'cat_beverages',
      categoryName: 'Beverages',
      price: 120.00,
      type: MenuItemType.veg,
    ),

    // Starters
    MenuItem(
      id: 'item_kebab_platter',
      name: 'Kebab Platter',
      shortCode: 'KBP',
      categoryId: 'cat_starters',
      categoryName: 'Starters',
      price: 250.00,
      type: MenuItemType.nonVeg,
      isFavorite: true,
      variants: const [
        MenuItemVariant(id: 'var_small', name: 'Small', price: 180.00),
        MenuItemVariant(id: 'var_medium', name: 'Medium', price: 250.00, isDefault: true),
        MenuItemVariant(id: 'var_large', name: 'Large', price: 350.00),
      ],
    ),
    MenuItem(
      id: 'item_bhaji_pav',
      name: 'Bhaji Pav',
      shortCode: 'BJP',
      categoryId: 'cat_starters',
      categoryName: 'Starters',
      price: 120.00,
      type: MenuItemType.veg,
      variants: const [
        MenuItemVariant(id: 'var_butter', name: 'Butter', price: 428.57, isDefault: true),
        MenuItemVariant(id: 'var_cheese', name: 'Cheese', price: 480.00),
      ],
    ),
    const MenuItem(
      id: 'item_coke',
      name: 'Coke',
      shortCode: 'COK',
      categoryId: 'cat_softdrinks',
      categoryName: 'Soft Drinks',
      price: 47.62,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_apple_pie',
      name: 'Apple Pie',
      shortCode: 'APP',
      categoryId: 'cat_desserts',
      categoryName: 'Desserts',
      price: 260.00,
      type: MenuItemType.veg,
    ),

    // Main Course
    MenuItem(
      id: 'item_butter_chicken',
      name: 'Butter Chicken',
      shortCode: 'BTC',
      categoryId: 'cat_maincourse',
      categoryName: 'Main Course',
      price: 320.00,
      type: MenuItemType.nonVeg,
      isFavorite: true,
      variants: const [
        MenuItemVariant(id: 'var_half', name: 'Half', price: 180.00),
        MenuItemVariant(id: 'var_full', name: 'Full', price: 320.00, isDefault: true),
      ],
      addons: const [
        MenuItemAddon(id: 'addon_extra_gravy', name: 'Extra Gravy', price: 40.00),
        MenuItemAddon(id: 'addon_boneless', name: 'Boneless', price: 50.00),
        MenuItemAddon(id: 'addon_extra_butter', name: 'Extra Butter', price: 30.00),
      ],
    ),
    MenuItem(
      id: 'item_dal_makhani',
      name: 'Dal Makhani',
      shortCode: 'DLM',
      categoryId: 'cat_maincourse',
      categoryName: 'Main Course',
      price: 220.00,
      type: MenuItemType.veg,
      addons: const [
        MenuItemAddon(id: 'addon_extra_cream', name: 'Extra Cream', price: 25.00),
        MenuItemAddon(id: 'addon_tadka', name: 'Extra Tadka', price: 20.00),
      ],
    ),
    MenuItem(
      id: 'item_paneer_tikka',
      name: 'Paneer Tikka Masala',
      shortCode: 'PTM',
      categoryId: 'cat_maincourse',
      categoryName: 'Main Course',
      price: 280.00,
      type: MenuItemType.veg,
      isFavorite: true,
      variants: const [
        MenuItemVariant(id: 'var_half_ptm', name: 'Half', price: 160.00),
        MenuItemVariant(id: 'var_full_ptm', name: 'Full', price: 280.00, isDefault: true),
      ],
      addons: const [
        MenuItemAddon(id: 'addon_extra_paneer', name: 'Extra Paneer', price: 60.00),
        MenuItemAddon(id: 'addon_cheese_top', name: 'Cheese Topping', price: 40.00),
      ],
    ),
    MenuItem(
      id: 'item_biryani',
      name: 'Chicken Biryani',
      shortCode: 'CBR',
      categoryId: 'cat_maincourse',
      categoryName: 'Main Course',
      price: 350.00,
      type: MenuItemType.nonVeg,
      variants: const [
        MenuItemVariant(id: 'var_single', name: 'Single', price: 200.00),
        MenuItemVariant(id: 'var_double', name: 'Double', price: 350.00, isDefault: true),
        MenuItemVariant(id: 'var_family', name: 'Family Pack', price: 650.00),
      ],
      addons: const [
        MenuItemAddon(id: 'addon_raita', name: 'Raita', price: 40.00),
        MenuItemAddon(id: 'addon_extra_chicken', name: 'Extra Chicken', price: 80.00),
        MenuItemAddon(id: 'addon_egg', name: 'Extra Egg', price: 25.00),
        MenuItemAddon(id: 'addon_salan', name: 'Mirchi Ka Salan', price: 50.00),
      ],
    ),
    MenuItem(
      id: 'item_naan',
      name: 'Butter Naan',
      shortCode: 'NAN',
      categoryId: 'cat_maincourse',
      categoryName: 'Main Course',
      price: 50.00,
      type: MenuItemType.veg,
      variants: const [
        MenuItemVariant(id: 'var_plain', name: 'Plain', price: 40.00),
        MenuItemVariant(id: 'var_butter_naan', name: 'Butter', price: 50.00, isDefault: true),
        MenuItemVariant(id: 'var_garlic', name: 'Garlic', price: 60.00),
        MenuItemVariant(id: 'var_cheese_naan', name: 'Cheese', price: 80.00),
      ],
    ),

    // Mocktails
    const MenuItem(
      id: 'item_blue_lagoon',
      name: 'Blue Lagoon',
      shortCode: 'BLG',
      categoryId: 'cat_mocktails',
      categoryName: 'Mocktails',
      price: 150.00,
      type: MenuItemType.veg,
    ),
    const MenuItem(
      id: 'item_mojito',
      name: 'Virgin Mojito',
      shortCode: 'VMJ',
      categoryId: 'cat_mocktails',
      categoryName: 'Mocktails',
      price: 140.00,
      type: MenuItemType.veg,
    ),
  ];

  static List<MenuItem> getItemsByCategory(String categoryId) {
    return items.where((i) => i.categoryId == categoryId).toList();
  }

  static List<MenuItem> getFavoriteItems() {
    return items.where((i) => i.isFavorite).toList();
  }

  static MenuItem? getItemById(String itemId) {
    try {
      return items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  static List<MenuItem> searchItems(String query) {
    final lowerQuery = query.toLowerCase();
    return items.where((i) =>
      i.name.toLowerCase().contains(lowerQuery) ||
      i.shortCode.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
