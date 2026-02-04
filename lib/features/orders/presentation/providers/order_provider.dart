import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../domain/entities/entities.dart';

const _uuid = Uuid();

// Current order provider (for the active table)
final currentOrderProvider = StateNotifierProvider<CurrentOrderNotifier, Order?>((ref) {
  return CurrentOrderNotifier();
});

// All orders provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, Map<String, Order>>((ref) {
  return OrdersNotifier();
});

// Order by table ID
final orderByTableProvider = Provider.family<Order?, String>((ref, tableId) {
  final orders = ref.watch(ordersProvider);
  return orders.values.where((o) => o.tableId == tableId && o.isActive).firstOrNull;
});

// KOTs provider
final kotsProvider = StateNotifierProvider<KotsNotifier, List<Kot>>((ref) {
  return KotsNotifier();
});

// KOTs by order
final kotsByOrderProvider = Provider.family<List<Kot>, String>((ref, orderId) {
  final kots = ref.watch(kotsProvider);
  return kots.where((k) => k.orderId == orderId).toList();
});

class CurrentOrderNotifier extends StateNotifier<Order?> {
  CurrentOrderNotifier() : super(null);

  void createOrder({
    required String tableId,
    required String tableName,
    required String captainId,
    required String captainName,
    int guestCount = 1,
    OrderType type = OrderType.dineIn,
  }) {
    state = Order(
      id: _uuid.v4(),
      tableId: tableId,
      tableName: tableName,
      type: type,
      captainId: captainId,
      captainName: captainName,
      guestCount: guestCount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void loadOrder(Order order) {
    state = order;
  }

  void addItem(MenuItem menuItem, {
    MenuItemVariant? variant,
    List<MenuItemAddon>? addons,
    int quantity = 1,
  }) {
    if (state == null) return;

    final orderItem = OrderItem.fromMenuItem(
      menuItem,
      id: _uuid.v4(),
      variant: variant,
      selectedAddons: addons,
      quantity: quantity,
    );

    final updatedItems = [...state!.items, orderItem];
    state = state!.copyWith(items: updatedItems).recalculate();
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (state == null) return;

    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state!.items.map((item) {
      if (item.id == itemId && item.canModify) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state!.copyWith(items: updatedItems).recalculate();
  }

  void removeItem(String itemId) {
    if (state == null) return;

    final item = state!.items.firstWhere((i) => i.id == itemId);
    if (!item.canModify) return;

    final updatedItems = state!.items.where((i) => i.id != itemId).toList();
    state = state!.copyWith(items: updatedItems).recalculate();
  }

  void markItemsAsKot(List<String> itemIds, String kotId) {
    if (state == null) return;

    final updatedItems = state!.items.map((item) {
      if (itemIds.contains(item.id)) {
        return item.copyWith(
          status: OrderItemStatus.kotGenerated,
          kotId: kotId,
        );
      }
      return item;
    }).toList();

    state = state!.copyWith(items: updatedItems);
  }

  void applyDiscount(double amount) {
    if (state == null) return;
    state = state!.recalculate(discount: amount);
  }

  void updateCustomerDetails({
    String? name,
    String? phone,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      customerName: name,
      customerPhone: phone,
      updatedAt: DateTime.now(),
    );
  }

  void updateNotes(String? notes) {
    if (state == null) return;
    state = state!.copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );
  }

  void updateGuestCount(int count) {
    if (state == null) return;
    state = state!.copyWith(
      guestCount: count,
      updatedAt: DateTime.now(),
    );
  }

  void clear() {
    state = null;
  }
}

class OrdersNotifier extends StateNotifier<Map<String, Order>> {
  OrdersNotifier() : super({});

  void addOrder(Order order) {
    state = {...state, order.id: order};
  }

  void updateOrder(Order order) {
    state = {...state, order.id: order};
  }

  void completeOrder(String orderId) {
    if (state.containsKey(orderId)) {
      state = {
        ...state,
        orderId: state[orderId]!.copyWith(status: OrderStatus.completed),
      };
    }
  }

  void cancelOrder(String orderId) {
    if (state.containsKey(orderId)) {
      state = {
        ...state,
        orderId: state[orderId]!.copyWith(status: OrderStatus.cancelled),
      };
    }
  }

  void handleOrderEvent(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'ORDER_UPDATED':
        final order = Order.fromJson(data);
        updateOrder(order);
        break;
    }
  }
}

class KotsNotifier extends StateNotifier<List<Kot>> {
  KotsNotifier() : super([]);
  int _kotCounter = 0;

  Kot createKot({
    required String orderId,
    required String tableId,
    required String tableName,
    required List<OrderItem> items,
    required String captainId,
    required String captainName,
    String? notes,
  }) {
    _kotCounter++;
    final kot = Kot(
      id: _uuid.v4(),
      orderId: orderId,
      tableId: tableId,
      tableName: tableName,
      kotNumber: _kotCounter,
      items: items,
      captainId: captainId,
      captainName: captainName,
      notes: notes,
      createdAt: DateTime.now(),
    );

    state = [...state, kot];
    return kot;
  }

  void updateKotStatus(String kotId, KotStatus status) {
    state = state.map((kot) {
      if (kot.id == kotId) {
        return kot.copyWith(
          status: status,
          printedAt: status == KotStatus.printed ? DateTime.now() : kot.printedAt,
        );
      }
      return kot;
    }).toList();
  }

  void cancelKot(String kotId) {
    updateKotStatus(kotId, KotStatus.cancelled);
  }
}
