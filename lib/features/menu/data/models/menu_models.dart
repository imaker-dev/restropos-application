/// API Models for Menu Module (Categories & Items)

enum MenuItemType { veg, nonVeg, egg }

class ApiCategory {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final String? image;
  final int? parentId;
  final int? sortOrder;
  final bool isActive;
  final List<ApiCategory>? children;
  final int? itemCount;
  final List<ApiMenuItem>? items;

  const ApiCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.image,
    this.parentId,
    this.sortOrder,
    this.isActive = true,
    this.children,
    this.itemCount,
    this.items,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) {
    // Parse isActive from various formats (int, bool, string)
    bool parseIsActive(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return true;
    }

    return ApiCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? json['color_code'] as String?,
      image:
          json['img'] as String? ??
          json['image'] as String? ??
          json['image_url'] as String?,
      parentId: json['parentId'] as int? ?? json['parent_id'] as int?,
      sortOrder: json['sortOrder'] as int? ?? json['display_order'] as int?,
      isActive: parseIsActive(json['isActive'] ?? json['is_active']),
      children: (json['children'] as List?)
          ?.map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCount:
          json['count'] as int? ??
          json['itemCount'] as int? ??
          json['item_count'] as int?,
      items: (json['items'] as List?)
          ?.map((e) => ApiMenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'color': color,
    'image': image,
    'parentId': parentId,
    'sortOrder': sortOrder,
    'isActive': isActive,
  };
}

class ApiMenuItem {
  final int id;
  final String name;
  final String? shortName;
  final String? shortCode;
  final String? description;
  final String? image;
  final double price;
  final double? basePrice;
  final int categoryId;
  final String? categoryName;
  final String? itemType;
  final String? badge;
  final bool isAvailable;
  final bool isFeatured;
  final bool isRecommended;
  final bool isVeg;
  final bool hasVariants;
  final bool hasAddons;
  final bool allowSpecialNotes;
  final int? preparationTime;
  final String? station;
  final int? kitchenStationId;
  final String? stationType;
  final TaxGroup? taxGroup;
  final List<ApiItemVariant>? variants;
  final List<AddonGroup>? addonGroups;
  final List<ApiItemAddon>? addons;
  final List<String>? tags;
  final int? sortOrder;

  const ApiMenuItem({
    required this.id,
    required this.name,
    this.shortName,
    this.shortCode,
    this.description,
    this.image,
    required this.price,
    this.basePrice,
    required this.categoryId,
    this.categoryName,
    this.itemType,
    this.badge,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isRecommended = false,
    this.isVeg = false,
    this.hasVariants = false,
    this.hasAddons = false,
    this.allowSpecialNotes = true,
    this.preparationTime,
    this.station,
    this.kitchenStationId,
    this.stationType,
    this.taxGroup,
    this.variants,
    this.addonGroups,
    this.addons,
    this.tags,
    this.sortOrder,
  });

  factory ApiMenuItem.fromJson(Map<String, dynamic> json) {
    // Parse bool from various formats (int, bool, string)
    bool parseBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return defaultValue;
    }

    // Parse item type to determine veg/non-veg
    final itemType =
        json['type'] as String? ??
        json['itemType'] as String? ??
        json['item_type'] as String?;
    final isVeg = itemType == 'veg' || parseBool(json['isVeg']);

    // Parse price - can be string or number
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return ApiMenuItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName:
          json['short'] as String? ??
          json['shortName'] as String? ??
          json['short_name'] as String?,
      shortCode: json['shortCode'] as String? ?? json['short_code'] as String?,
      description: json['description'] as String?,
      image:
          json['img'] as String? ??
          json['image'] as String? ??
          json['imageUrl'] as String? ??
          json['image_url'] as String?,
      price: parsePrice(
        json['price'] ?? json['base_price'] ?? json['basePrice'],
      ),
      basePrice: parsePrice(json['basePrice'] ?? json['base_price']),
      categoryId:
          json['categoryId'] as int? ?? json['category_id'] as int? ?? 0,
      categoryName:
          json['categoryName'] as String? ?? json['category_name'] as String?,
      itemType: itemType,
      badge: json['badge'] as String?,
      isAvailable: parseBool(json['isAvailable'] ?? json['is_available'], true),
      isFeatured: parseBool(json['isFeatured'] ?? json['is_featured']),
      isRecommended: parseBool(
        json['recommended'] ?? json['isRecommended'] ?? json['is_recommended'],
      ),
      isVeg: isVeg,
      hasVariants:
          parseBool(json['hasVariants'] ?? json['has_variants']) ||
          (json['variants'] as List?)?.isNotEmpty == true,
      hasAddons:
          parseBool(json['hasAddons'] ?? json['has_addons']) ||
          (json['addons'] as List?)?.isNotEmpty == true ||
          (json['addonGroups'] as List?)?.isNotEmpty == true,
      allowSpecialNotes: parseBool(
        json['allowSpecialNotes'] ?? json['allow_special_notes'],
        true,
      ),
      preparationTime:
          json['preparationTime'] as int? ??
          json['preparation_time_mins'] as int?,
      station: json['station'] as String?,
      kitchenStationId:
          json['kitchenStationId'] as int? ??
          json['kitchen_station_id'] as int?,
      stationType:
          json['stationType'] as String? ?? json['station_type'] as String?,
      taxGroup: json['taxGroup'] != null
          ? TaxGroup.fromJson(json['taxGroup'] as Map<String, dynamic>)
          : (json['tax_group_id'] != null
                ? TaxGroup(
                    id: json['tax_group_id'] as int? ?? 0,
                    name: json['tax_group_name'] as String? ?? '',
                    rate: parsePrice(json['tax_rate']),
                  )
                : null),
      variants: (json['variants'] as List?)
          ?.map((e) => ApiItemVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      addonGroups: (json['addons'] as List? ?? json['addonGroups'] as List?)
          ?.map((e) => AddonGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      addons: null,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
      sortOrder: json['sortOrder'] as int? ?? json['display_order'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortCode': shortCode,
    'description': description,
    'image': image,
    'price': price,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'isAvailable': isAvailable,
    'isFeatured': isFeatured,
    'isVeg': isVeg,
    'hasVariants': hasVariants,
    'hasAddons': hasAddons,
    'station': station,
  };

  MenuItemType get type => isVeg ? MenuItemType.veg : MenuItemType.nonVeg;

  /// Get all addons from addon groups or direct addons list
  List<ApiItemAddon> get allAddons {
    if (addonGroups != null && addonGroups!.isNotEmpty) {
      return addonGroups!.expand((g) => g.addons).toList();
    }
    return addons ?? [];
  }
}

class ApiItemVariant {
  final int id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isAvailable;

  const ApiItemVariant({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
    this.isAvailable = true,
  });

  factory ApiItemVariant.fromJson(Map<String, dynamic> json) {
    // Parse bool from various formats
    bool parseBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return defaultValue;
    }

    // Parse price - can be string or number
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return ApiItemVariant(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: parsePrice(json['price']),
      isDefault: parseBool(
        json['default'] ?? json['isDefault'] ?? json['is_default'],
      ),
      isAvailable: parseBool(
        json['isAvailable'] ?? json['is_available'] ?? json['is_active'],
        true,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'isDefault': isDefault,
    'isAvailable': isAvailable,
  };
}

class TaxGroup {
  final int id;
  final String name;
  final double rate;

  const TaxGroup({required this.id, required this.name, required this.rate});

  factory TaxGroup.fromJson(Map<String, dynamic> json) {
    return TaxGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AddonGroup {
  final int id;
  final String name;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<ApiItemAddon> addons;

  const AddonGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelection = 0,
    this.maxSelection = 99,
    this.addons = const [],
  });

  factory AddonGroup.fromJson(Map<String, dynamic> json) {
    // Parse required/isRequired - can be int (1/0) or bool
    bool parseRequired(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return AddonGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isRequired: parseRequired(json['required'] ?? json['isRequired']),
      minSelection: json['min'] as int? ?? json['minSelection'] as int? ?? 0,
      maxSelection: json['max'] as int? ?? json['maxSelection'] as int? ?? 99,
      addons: (json['options'] as List? ?? json['addons'] as List? ?? [])
          .map((e) => ApiItemAddon.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiItemAddon {
  final int id;
  final String name;
  final double price;
  final String? itemType;
  final String? image;
  final bool isAvailable;
  final String? group;

  const ApiItemAddon({
    required this.id,
    required this.name,
    required this.price,
    this.itemType,
    this.image,
    this.isAvailable = true,
    this.group,
  });

  factory ApiItemAddon.fromJson(Map<String, dynamic> json) {
    return ApiItemAddon(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      itemType: json['type'] as String? ?? json['itemType'] as String?,
      image: json['img'] as String? ?? json['image'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      group: json['group'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'isAvailable': isAvailable,
    'group': group,
  };

  bool get isVeg => itemType == 'veg';
}

class CaptainMenu {
  final int outletId;
  final DateTime? generatedAt;
  final String? timeSlot;
  final MenuSummary? summary;
  final List<ApiCategory> menu;
  final List<ApiMenuItem>? featuredItems;

  const CaptainMenu({
    required this.outletId,
    this.generatedAt,
    this.timeSlot,
    this.summary,
    required this.menu,
    this.featuredItems,
  });

  factory CaptainMenu.fromJson(Map<String, dynamic> json) {
    // Parse outletId - can be string or int
    int parseOutletId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return CaptainMenu(
      outletId: parseOutletId(json['outletId'] ?? json['outlet_id']),
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
      timeSlot: json['timeSlot'] as String?,
      summary: json['summary'] != null
          ? MenuSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      menu:
          (json['menu'] as List?)
              ?.map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featuredItems: (json['featuredItems'] as List?)
          ?.map((e) => ApiMenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get all categories from menu
  List<ApiCategory> get categories => menu;

  /// Get all items from all categories with categoryId set
  List<ApiMenuItem> get items {
    final result = <ApiMenuItem>[];
    for (final category in menu) {
      if (category.items != null) {
        for (final item in category.items!) {
          // Set categoryId if not already set
          if (item.categoryId == 0) {
            result.add(
              ApiMenuItem(
                id: item.id,
                name: item.name,
                shortName: item.shortName,
                shortCode: item.shortCode,
                description: item.description,
                image: item.image,
                price: item.price,
                basePrice: item.basePrice,
                categoryId: category.id,
                categoryName: category.name,
                itemType: item.itemType,
                badge: item.badge,
                isAvailable: item.isAvailable,
                isFeatured: item.isFeatured,
                isRecommended: item.isRecommended,
                isVeg: item.isVeg,
                hasVariants: item.hasVariants,
                hasAddons: item.hasAddons,
                allowSpecialNotes: item.allowSpecialNotes,
                preparationTime: item.preparationTime,
                station: item.station,
                kitchenStationId: item.kitchenStationId,
                stationType: item.stationType,
                taxGroup: item.taxGroup,
                variants: item.variants,
                addonGroups: item.addonGroups,
                addons: item.addons,
                tags: item.tags,
                sortOrder: item.sortOrder,
              ),
            );
          } else {
            result.add(item);
          }
        }
      }
    }
    return result;
  }
}

class MenuSummary {
  final int categories;
  final int items;

  const MenuSummary({required this.categories, required this.items});

  factory MenuSummary.fromJson(Map<String, dynamic> json) {
    return MenuSummary(
      categories: json['categories'] as int? ?? 0,
      items: json['items'] as int? ?? 0,
    );
  }
}

/// Search API response model
class MenuSearchResponse {
  final String query;
  final List<ApiCategory> matchingCategories;
  final List<ApiMenuItem> matchingItems;
  final int totalCategories;
  final int totalItems;

  const MenuSearchResponse({
    required this.query,
    this.matchingCategories = const [],
    this.matchingItems = const [],
    this.totalCategories = 0,
    this.totalItems = 0,
  });

  factory MenuSearchResponse.fromJson(Map<String, dynamic> json) {
    return MenuSearchResponse(
      query: json['query'] as String? ?? '',
      matchingCategories:
          (json['matchingCategories'] as List?)
              ?.map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchingItems:
          (json['matchingItems'] as List?)
              ?.map((e) => ApiMenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCategories: json['totalCategories'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }

  /// Get all items: items directly matched + items inside matched categories
  List<ApiMenuItem> get allItems {
    final result = <ApiMenuItem>[];
    // Add items from matching categories
    for (final cat in matchingCategories) {
      if (cat.items != null) {
        for (final item in cat.items!) {
          if (item.categoryId == 0) {
            result.add(
              ApiMenuItem(
                id: item.id,
                name: item.name,
                shortName: item.shortName,
                shortCode: item.shortCode,
                description: item.description,
                image: item.image,
                price: item.price,
                basePrice: item.basePrice,
                categoryId: cat.id,
                categoryName: cat.name,
                itemType: item.itemType,
                isAvailable: item.isAvailable,
                isVeg: item.isVeg,
                hasVariants: item.hasVariants,
                hasAddons: item.hasAddons,
                preparationTime: item.preparationTime,
                variants: item.variants,
                addonGroups: item.addonGroups,
                addons: item.addons,
                tags: item.tags,
              ),
            );
          } else {
            result.add(item);
          }
        }
      }
    }
    // Add directly matching items
    result.addAll(matchingItems);
    return result;
  }
}

class CalculateItemRequest {
  final int itemId;
  final int quantity;
  final int? variantId;
  final List<int>? addonIds;

  const CalculateItemRequest({
    required this.itemId,
    required this.quantity,
    this.variantId,
    this.addonIds,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'quantity': quantity,
    'variantId': variantId,
    'addonIds': addonIds ?? [],
  };
}

class CalculateItemResponse {
  final double itemTotal;
  final double variantPrice;
  final double addonsTotal;
  final double grandTotal;

  const CalculateItemResponse({
    required this.itemTotal,
    required this.variantPrice,
    required this.addonsTotal,
    required this.grandTotal,
  });

  factory CalculateItemResponse.fromJson(Map<String, dynamic> json) {
    return CalculateItemResponse(
      itemTotal: (json['itemTotal'] as num?)?.toDouble() ?? 0,
      variantPrice: (json['variantPrice'] as num?)?.toDouble() ?? 0,
      addonsTotal: (json['addonsTotal'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
