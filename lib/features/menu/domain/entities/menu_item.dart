import 'package:equatable/equatable.dart';

enum MenuItemType { veg, nonVeg, egg }

class MenuCategory extends Equatable {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final String? imageUrl;

  const MenuCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, sortOrder, isActive, imageUrl];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'imageUrl': imageUrl,
  };

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    sortOrder: json['sortOrder'] as int? ?? 0,
    isActive: json['isActive'] as bool? ?? true,
    imageUrl: json['imageUrl'] as String?,
  );
}

class MenuItemVariant extends Equatable {
  final String id;
  final String name;
  final double price;
  final bool isDefault;

  const MenuItemVariant({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, price, isDefault];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'isDefault': isDefault,
  };

  factory MenuItemVariant.fromJson(Map<String, dynamic> json) => MenuItemVariant(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

class MenuItemAddon extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? groupId;
  final String? groupName;

  const MenuItemAddon({
    required this.id,
    required this.name,
    required this.price,
    this.groupId,
    this.groupName,
  });

  @override
  List<Object?> get props => [id, name, price, groupId, groupName];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'groupId': groupId,
    'groupName': groupName,
  };

  factory MenuItemAddon.fromJson(Map<String, dynamic> json) => MenuItemAddon(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    groupId: json['groupId'] as String?,
    groupName: json['groupName'] as String?,
  );
}

class MenuItem extends Equatable {
  final String id;
  final String name;
  final String shortCode;
  final String categoryId;
  final String categoryName;
  final double price;
  final MenuItemType type;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFavorite;
  final List<MenuItemVariant> variants;
  final List<MenuItemAddon> addons;
  final int sortOrder;

  const MenuItem({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    this.type = MenuItemType.veg,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.isFavorite = false,
    this.variants = const [],
    this.addons = const [],
    this.sortOrder = 0,
  });

  bool get hasVariants => variants.isNotEmpty;
  bool get hasAddons => addons.isNotEmpty;

  double getEffectivePrice([MenuItemVariant? variant]) {
    if (variant != null) return variant.price;
    if (variants.isNotEmpty) {
      final defaultVariant = variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      );
      return defaultVariant.price;
    }
    return price;
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? shortCode,
    String? categoryId,
    String? categoryName,
    double? price,
    MenuItemType? type,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    bool? isFavorite,
    List<MenuItemVariant>? variants,
    List<MenuItemAddon>? addons,
    int? sortOrder,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isFavorite: isFavorite ?? this.isFavorite,
      variants: variants ?? this.variants,
      addons: addons ?? this.addons,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortCode': shortCode,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'price': price,
    'type': type.name,
    'description': description,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'isFavorite': isFavorite,
    'variants': variants.map((v) => v.toJson()).toList(),
    'addons': addons.map((a) => a.toJson()).toList(),
    'sortOrder': sortOrder,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    name: json['name'] as String,
    shortCode: json['shortCode'] as String,
    categoryId: json['categoryId'] as String,
    categoryName: json['categoryName'] as String,
    price: (json['price'] as num).toDouble(),
    type: MenuItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MenuItemType.veg,
    ),
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    isAvailable: json['isAvailable'] as bool? ?? true,
    isFavorite: json['isFavorite'] as bool? ?? false,
    variants: (json['variants'] as List<dynamic>?)
        ?.map((v) => MenuItemVariant.fromJson(v as Map<String, dynamic>))
        .toList() ?? [],
    addons: (json['addons'] as List<dynamic>?)
        ?.map((a) => MenuItemAddon.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
    sortOrder: json['sortOrder'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [
    id, name, shortCode, categoryId, categoryName, price, type,
    description, imageUrl, isAvailable, isFavorite, variants, addons, sortOrder,
  ];
}
