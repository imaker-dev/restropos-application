import 'package:equatable/equatable.dart';
import '../../../menu/domain/entities/menu_item.dart';

enum OrderItemStatus {
  pending,
  kotGenerated,
  preparing,
  ready,
  served,
  cancelled,
}

class SelectedAddon extends Equatable {
  final String id;
  final String name;
  final double price;

  const SelectedAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory SelectedAddon.fromJson(Map<String, dynamic> json) => SelectedAddon(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
  );
}

class OrderItem extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? variantId;
  final String? variantName;
  final List<SelectedAddon> addons;
  final String? specialInstructions;
  final OrderItemStatus status;
  final String? kotId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.variantId,
    this.variantName,
    this.addons = const [],
    this.specialInstructions,
    this.status = OrderItemStatus.pending,
    this.kotId,
    required this.createdAt,
    required this.updatedAt,
  });

  double get addonsTotal => addons.fold(0, (sum, addon) => sum + addon.price);
  double get itemTotal => (unitPrice + addonsTotal) * quantity;

  bool get isPending => status == OrderItemStatus.pending;
  bool get hasKot => kotId != null;
  bool get canModify => status == OrderItemStatus.pending;
  bool get canCancel => status == OrderItemStatus.pending || status == OrderItemStatus.kotGenerated;

  OrderItem copyWith({
    String? id,
    String? menuItemId,
    String? name,
    int? quantity,
    double? unitPrice,
    String? variantId,
    String? variantName,
    List<SelectedAddon>? addons,
    String? specialInstructions,
    OrderItemStatus? status,
    String? kotId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      addons: addons ?? this.addons,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      status: status ?? this.status,
      kotId: kotId ?? this.kotId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'menuItemId': menuItemId,
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'variantId': variantId,
    'variantName': variantName,
    'addons': addons.map((a) => a.toJson()).toList(),
    'specialInstructions': specialInstructions,
    'status': status.name,
    'kotId': kotId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    menuItemId: json['menuItemId'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    variantId: json['variantId'] as String?,
    variantName: json['variantName'] as String?,
    addons: (json['addons'] as List<dynamic>?)
        ?.map((a) => SelectedAddon.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
    specialInstructions: json['specialInstructions'] as String?,
    status: OrderItemStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderItemStatus.pending,
    ),
    kotId: json['kotId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  factory OrderItem.fromMenuItem(MenuItem menuItem, {
    required String id,
    MenuItemVariant? variant,
    List<MenuItemAddon>? selectedAddons,
    int quantity = 1,
  }) {
    return OrderItem(
      id: id,
      menuItemId: menuItem.id,
      name: menuItem.name,
      quantity: quantity,
      unitPrice: variant?.price ?? menuItem.price,
      variantId: variant?.id,
      variantName: variant?.name,
      addons: selectedAddons?.map((a) => SelectedAddon(
        id: a.id,
        name: a.name,
        price: a.price,
      )).toList() ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id, menuItemId, name, quantity, unitPrice, variantId, variantName,
    addons, specialInstructions, status, kotId, createdAt, updatedAt,
  ];
}
