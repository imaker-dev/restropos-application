import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../menu/data/models/menu_models.dart';
import '../../../menu/menu.dart' hide MenuItemType;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../layout/data/repositories/layout_repository.dart';
import '../../../tables/data/models/table_details_model.dart';
import '../../../tables/tables.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/entities/order_item.dart';
import '../providers/order_provider.dart';
import '../providers/orders_provider.dart' as api;
import '../widgets/cancel_item_dialog.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/widgets.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String tableId;

  const OrderScreen({super.key, required this.tableId});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final _searchController = TextEditingController();
  final _mobileSearchController = TextEditingController();
  final _mobileSearchFocusNode = FocusNode();
  bool _isCategorySidebarOpen = false;

  // API integration state
  int? _apiOrderId;

  @override
  void initState() {
    super.initState();
    _initializeOrder();
  }

  @override
  void dispose() {
    // Reset order action state providers to avoid stale state
    ref.read(orderSavingProvider.notifier).state = false;
    ref.read(orderSendingKotProvider.notifier).state = false;
    ref.read(orderKotEnabledProvider.notifier).state = false;
    _searchController.dispose();
    _mobileSearchController.dispose();
    _mobileSearchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(menuSearchQueryProvider.notifier).state = query;
    final filter = ref.read(menuFilterProvider);
    if (query.trim().isNotEmpty) {
      ref.read(menuSearchProvider.notifier).search(query, filter: filter);
    } else {
      ref.read(menuSearchProvider.notifier).clear();
    }
  }

  void _onFilterChanged(String? filter) {
    final current = ref.read(menuFilterProvider);
    if (current == filter) return;
    ref.read(menuFilterProvider.notifier).state = filter;
    // Reload menu silently (no loader flash) - keeps old items visible until new data arrives
    ref.read(menuProvider.notifier).loadMenu(filter: filter, silent: true);
    // If searching, re-search with new filter
    final query = ref.read(menuSearchQueryProvider);
    if (query.trim().isNotEmpty) {
      ref.read(menuSearchProvider.notifier).search(query, filter: filter);
    }
  }

  void _initializeOrder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load menu from API
      ref.read(menuProvider.notifier).loadMenu();

      final table = ref.read(tableProvider(widget.tableId));
      final user = ref.read(currentUserProvider);

      if (table != null &&
          user != null &&
          table.status != TableStatus.available &&
          table.status != TableStatus.cleaning &&
          table.status != TableStatus.blocked) {
        // Always fetch fresh data from API for occupied/running/billing tables
        // This avoids stale cached data from previous sessions
        _fetchAndLoadTableDetails(table, user);
      } else if (table != null && user != null) {
        // Available table - create new order
        ref
            .read(currentOrderProvider.notifier)
            .createOrder(
              tableId: table.id,
              tableName: table.name,
              captainId: user.id.toString(),
              captainName: user.name,
              guestCount: table.guestCount ?? 1,
            );
        // Create API order in background
        _createApiOrder(table, user);
      }

      // Clear cached table details (no longer needed)
      ref.read(currentTableDetailsProvider.notifier).state = null;
    });
  }

  void _loadFromTableDetails(TableDetailsResponse details, dynamic user) {
    _apiOrderId = details.order!.id;
    ref
        .read(currentOrderProvider.notifier)
        .loadOrderFromTableDetails(
          tableDetails: details,
          captainId: user.id.toString(),
          captainName: user.name,
        );
    // If there are pending items on API (saved but not KOT'd), enable KOT
    final hasPendingApiItems = details.items.any(
      (i) => i.status.toLowerCase() == 'pending',
    );
    if (hasPendingApiItems) {
      ref.read(orderKotEnabledProvider.notifier).state = true;
    }
    // Clear the table details after loading
    ref.read(currentTableDetailsProvider.notifier).state = null;
  }

  Future<void> _fetchAndLoadTableDetails(
    RestaurantTable table,
    dynamic user,
  ) async {
    final tableIdInt = int.tryParse(table.id) ?? 0;
    debugPrint(
      '[OrderScreen] Fetching table details for occupied table $tableIdInt',
    );

    final repository = ref.read(layoutRepositoryProvider);
    final result = await repository.getTableDetails(tableIdInt);

    if (!mounted) return;

    result.when(
      success: (details, _) {
        if (details.hasActiveOrder) {
          _loadFromTableDetails(details, user);
        } else if (details.hasActiveSession) {
          // Has session but no order yet - create new order
          ref
              .read(currentOrderProvider.notifier)
              .createOrder(
                tableId: table.id,
                tableName: table.name,
                captainId: user.id.toString(),
                captainName: user.name,
                guestCount: details.session!.guestCount,
              );
          _createApiOrder(table, user);
        } else {
          // Fallback: create new order
          ref
              .read(currentOrderProvider.notifier)
              .createOrder(
                tableId: table.id,
                tableName: table.name,
                captainId: user.id.toString(),
                captainName: user.name,
                guestCount: table.guestCount ?? 1,
              );
          _createApiOrder(table, user);
        }
      },
      failure: (message, _, __) {
        debugPrint('[OrderScreen] Failed to fetch table details: $message');
        if (mounted) {
          Toast.error(context, 'Failed to load table details: $message');
        }
      },
    );
  }

  Future<void> _createApiOrder(RestaurantTable table, dynamic user) async {
    final floorId = ref.read(selectedFloorProvider);

    final result = await ref
        .read(api.ordersProvider.notifier)
        .createOrder(
          tableId: int.tryParse(table.id) ?? 0,
          guestCount: table.guestCount ?? 1,
          floorId: floorId,
          sectionId: int.tryParse(table.sectionId),
          customerName: null,
          customerPhone: null,
          specialInstructions: null,
        );

    result.when(
      success: (order, _) {
        debugPrint(
          '[OrderScreen] API order created: id=${order.id}, number=${order.orderNumber}',
        );
        if (mounted) {
          setState(() => _apiOrderId = order.id);
          // Update local order ID to match API
          final localOrder = ref.read(currentOrderProvider);
          if (localOrder != null) {
            ref
                .read(currentOrderProvider.notifier)
                .loadOrder(localOrder.copyWith(id: order.id.toString()));
          }
        }
      },
      failure: (message, _, __) {
        debugPrint('[OrderScreen] Failed to create API order: $message');
        if (mounted) {
          Toast.error(context, 'Failed to create order: $message');
        }
      },
    );
  }

  void _onMenuItemTap(ApiMenuItem item) {
    // Show selector sheet if item has variants OR addons
    if (item.hasVariants || item.hasAddons) {
      _showVariantSelector(item);
    } else {
      _showAddItemSheet(item);
    }
  }

  void _showAddItemSheet(ApiMenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddItemSheet(
          item: item,
          onAdd: (int quantity, String? instructions) {
            ref
                .read(currentOrderProvider.notifier)
                .addItem(
                  item,
                  quantity: quantity,
                  specialInstructions: instructions,
                );
            Navigator.pop(ctx);
            Toast.success(context, '${item.name} added');
          },
        ),
      ),
    );
  }

  void _showVariantSelector(ApiMenuItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: _VariantSelectorSheet(
          item: item,
          onSelect: (variant, addons) {
            ref
                .read(currentOrderProvider.notifier)
                .addItem(item, variant: variant, addons: addons);
            Navigator.pop(context);
            Toast.success(context, '${item.name} added');
          },
        ),
      ),
    );
  }

  Future<void> _onGenerateKot() async {
    if (_apiOrderId == null || ref.read(orderSendingKotProvider)) return;

    ref.read(orderSendingKotProvider.notifier).state = true;

    final result = await ref
        .read(api.kotProvider.notifier)
        .sendKot(_apiOrderId!);

    if (!mounted) return;

    result.when(
      success: (response, _) {
        debugPrint(
          '[OrderScreen] KOT sent: ${response.tickets.length} tickets',
        );
        // Mark all pending items as KOT generated
        final order = ref.read(currentOrderProvider);
        if (order != null) {
          final pendingIds = order.pendingItems.map((i) => i.id).toList();
          if (pendingIds.isNotEmpty) {
            ref
                .read(currentOrderProvider.notifier)
                .markItemsAsKot(
                  pendingIds,
                  response.tickets.isNotEmpty
                      ? response.tickets.first.id.toString()
                      : 'kot',
                );
          }
        }

        // Update table status to running
        ref
            .read(tablesProvider.notifier)
            .updateTableStatus(widget.tableId, TableStatus.running);

        ref.read(orderSendingKotProvider.notifier).state = false;
        ref.read(orderKotEnabledProvider.notifier).state = false;

        final ticketNumbers = response.tickets
            .map((t) => t.kotNumber)
            .join(', ');
        Toast.success(context, 'KOT sent: $ticketNumbers');
      },
      failure: (message, _, __) {
        debugPrint('[OrderScreen] Failed to send KOT: $message');
        ref.read(orderSendingKotProvider.notifier).state = false;
        Toast.error(context, 'Failed to send KOT: $message');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar - Categories
        SizedBox(
          width: 140,
          child: Column(
            children: [
              // Header
              Container(
                padding: AppSpacing.paddingSm,
                color: AppColors.secondary,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const Flexible(
                      child: Text(
                        'Table Started By',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Date/Time display
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                color: AppColors.secondary,
                child: Text(
                  _formatDateTime(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              // Categories
              const Expanded(child: CategoryList()),
            ],
          ),
        ),
        // Center - Menu items
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Search bar + filter chips
              Container(
                padding: AppSpacing.paddingSm,
                color: AppColors.surface,
                child: Column(
                  children: [
                    SearchInput(
                      controller: _searchController,
                      hint: 'Search menu items...',
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildFilterChips(),
                  ],
                ),
              ),
              // Menu items grid
              Expanded(child: _buildMenuGrid()),
            ],
          ),
        ),
        // Right panel - Order summary
        SizedBox(
          width: 380,
          child: OrderSummaryPanel(
            onSave: () => _saveOrder(),
            onKot: () => _onGenerateKot(),
            onBill: () => _onGenerateBill(),
            onCancelOrder: () => _onCancelOrder(),
            onItemTap: _onItemTap,
            onItemCancel: _onCancelItem,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Categories (horizontal at top)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Back button and categories
              Container(
                color: AppColors.surface,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: CategoryList(direction: Axis.horizontal),
                    ),
                  ],
                ),
              ),
              // Search + filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.surface,
                child: Column(
                  children: [
                    SearchInput(
                      controller: _searchController,
                      hint: 'Search menu items...',
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 4),
                    _buildFilterChips(),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Menu grid
              Expanded(child: _buildMenuGrid()),
            ],
          ),
        ),
        // Order panel
        SizedBox(
          width: 320,
          child: OrderSummaryPanel(
            onSave: () => _saveOrder(),
            onKot: () => _onGenerateKot(),
            onBill: () => _onGenerateBill(),
            onCancelOrder: () => _onCancelOrder(),
            onItemTap: _onItemTap,
            onItemCancel: _onCancelItem,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    // Read table once for initial values - don't watch to avoid rebuilds
    final table = ref.read(tableProvider(widget.tableId));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        leadingWidth: 40,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: table?.status.color ?? AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                table?.name ?? 'Table',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${table?.guestCount ?? 0}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Icon(
              Icons.people_outline,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        actions: [
          // Item count badge - scoped Consumer to avoid full layout rebuild
          Consumer(
            builder: (context, ref, _) {
              final itemCount =
                  ref.watch(currentOrderProvider)?.totalItems ?? 0;
              if (itemCount <= 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, size: 20),
            onPressed: () => _showCustomerDialogMobile(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Search bar with category toggle
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: Row(
                  children: [
                    // Category sidebar toggle
                    Material(
                      color: _isCategorySidebarOpen
                          ? AppColors.primary
                          : AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _isCategorySidebarOpen = !_isCategorySidebarOpen;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _isCategorySidebarOpen ? Icons.close : Icons.menu,
                            size: 20,
                            color: _isCategorySidebarOpen
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchInput(
                        controller: _mobileSearchController,
                        focusNode: _mobileSearchFocusNode,
                        hint: 'Search menu...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
              // Filter chips
              _buildFilterChips(),
              // Menu grid
              Expanded(child: _buildMenuGrid()),
              // Order summary bar - scoped Consumer to avoid full layout rebuild
              Consumer(
                builder: (context, ref, _) {
                  final order = ref.watch(currentOrderProvider);
                  final kotItemCount =
                      order?.items.where((i) => !i.canModify).length ?? 0;
                  final pendingItemCount = order?.pendingItems.length ?? 0;
                  final total = order?.grandTotal ?? 0;
                  if (kotItemCount <= 0 && pendingItemCount <= 0) {
                    return const SizedBox.shrink();
                  }
                  return _MobileOrderSummaryBar(
                    kotItemCount: kotItemCount,
                    pendingItemCount: pendingItemCount,
                    total: total,
                    onViewOrder: _showOrderSheet,
                  );
                },
              ),
            ],
          ),
          // Collapsible category sidebar overlay
          if (_isCategorySidebarOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Sidebar header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              _isCategorySidebarOpen = false;
                            }),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category list
                    const Expanded(
                      child: CategoryList(direction: Axis.vertical),
                    ),
                  ],
                ),
              ),
            ),
          // Overlay to close sidebar when tapping outside
          if (_isCategorySidebarOpen)
            Positioned.fill(
              left: 160,
              child: GestureDetector(
                onTap: () => setState(() {
                  _isCategorySidebarOpen = false;
                }),
                child: Container(color: Colors.black26),
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomerDialogMobile(BuildContext context) {
    final order = ref.read(currentOrderProvider);
    if (order == null) return;

    final nameController = TextEditingController(
      text: order.customerName ?? '',
    );
    final phoneController = TextEditingController(
      text: order.customerPhone ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customer Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter customer name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(currentOrderProvider.notifier)
                          .updateCustomerDetails(
                            name: nameController.text.trim().isEmpty
                                ? null
                                : nameController.text.trim(),
                            phone: phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(menuFilterProvider);
    const filters = <String?, String>{
      null: 'All',
      'veg': 'Veg',
      'non_veg': 'Non-Veg',
      'liquor': 'Liquor',
    };

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: filters.entries.map((entry) {
          final isSelected = currentFilter == entry.key;
          final Color chipColor;
          final IconData? chipIcon;
          switch (entry.key) {
            case 'veg':
              chipColor = AppColors.success;
              chipIcon = Icons.eco;
              break;
            case 'non_veg':
              chipColor = AppColors.error;
              chipIcon = Icons.set_meal;
              break;
            case 'liquor':
              chipColor = Colors.amber.shade700;
              chipIcon = Icons.local_bar;
              break;
            default:
              chipColor = AppColors.primary;
              chipIcon = null;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chipIcon != null) ...[
                    Icon(
                      chipIcon,
                      size: 14,
                      color: isSelected ? Colors.white : chipColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(entry.key),
              backgroundColor: AppColors.surface,
              selectedColor: chipColor,
              side: BorderSide(
                color: isSelected ? chipColor : AppColors.divider,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuState = ref.watch(menuProvider);
    final searchState = ref.watch(menuSearchProvider);
    final query = ref.watch(menuSearchQueryProvider);
    final items = ref.watch(searchedMenuItemsProvider);

    // Show loading indicator
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show search loading
    if (query.trim().isNotEmpty && searchState.isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Searching...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Show error if any
    if (menuState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              menuState.error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final filter = ref.read(menuFilterProvider);
                ref.read(menuProvider.notifier).loadMenu(filter: filter);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.trim().isNotEmpty
                  ? Icons.search_off
                  : Icons.restaurant_menu,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              query.trim().isNotEmpty
                  ? 'No items match "$query"'
                  : 'No items found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final crossAxisCount = switch (deviceType) {
          DeviceType.mobile => 2,
          DeviceType.tablet => 3,
          DeviceType.desktop => 4,
        };

        return GridView.builder(
          padding: AppSpacing.paddingSm,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MenuItemCard(item: item, onTap: () => _onMenuItemTap(item));
          },
        );
      },
    );
  }

  void _showOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => OrderSummaryPanel(
          onSave: () {
            _saveOrder();
            // Don't close - captain navigates back manually
          },
          onKot: () {
            _onGenerateKot();
            // Don't close - captain navigates back manually
          },
          onBill: () {
            Navigator.pop(sheetContext);
            _onGenerateBill();
          },
          onCancelOrder: () {
            Navigator.pop(sheetContext);
            _onCancelOrder();
          },
          onItemTap: (item) {
            Navigator.pop(sheetContext);
            _onItemTap(item);
          },
          onItemCancel: (item) {
            Navigator.pop(sheetContext);
            _onCancelItem(item);
          },
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    final order = ref.read(currentOrderProvider);
    if (order == null || _apiOrderId == null || ref.read(orderSavingProvider)) {
      return;
    }

    final pendingItems = order.pendingItems;
    if (pendingItems.isEmpty) {
      Toast.info(context, 'No new items to save');
      return;
    }

    ref.read(orderSavingProvider.notifier).state = true;

    // Convert local pending items to API request format
    final apiItems = pendingItems.map((item) {
      return CreateOrderItemRequest(
        itemId: int.tryParse(item.menuItemId) ?? 0,
        quantity: item.quantity,
        variantId: item.variantId != null
            ? int.tryParse(item.variantId!)
            : null,
        addonIds: item.addons.isNotEmpty
            ? item.addons.map((a) => int.tryParse(a.id) ?? 0).toList()
            : null,
        specialInstructions: item.specialInstructions,
      );
    }).toList();

    final result = await ref
        .read(api.ordersProvider.notifier)
        .addItems(orderId: _apiOrderId!, items: apiItems);

    if (!mounted) return;

    result.when(
      success: (apiOrder, _) {
        debugPrint(
          '[OrderScreen] Items saved: ${apiItems.length} items, order total=${apiOrder.total}',
        );
        // Mark pending items as KOT generated (saved to server, ready for KOT)
        final pendingIds = pendingItems.map((i) => i.id).toList();
        ref
            .read(currentOrderProvider.notifier)
            .markItemsAsKot(
              pendingIds,
              'saved-${DateTime.now().millisecondsSinceEpoch}',
            );

        // Update local order totals from API response
        final currentOrder = ref.read(currentOrderProvider);
        if (currentOrder != null) {
          ref
              .read(currentOrderProvider.notifier)
              .loadOrder(
                currentOrder.copyWith(
                  subtotal: apiOrder.subtotal,
                  taxAmount: apiOrder.taxAmount,
                  grandTotal: apiOrder.total,
                ),
              );
        }

        // Update table running total
        ref
            .read(tablesProvider.notifier)
            .updateRunningTotal(widget.tableId, apiOrder.total);

        ref.read(orderSavingProvider.notifier).state = false;
        ref.read(orderKotEnabledProvider.notifier).state = true;

        Toast.success(context, '${apiItems.length} items saved');
      },
      failure: (message, _, __) {
        debugPrint('[OrderScreen] Failed to save items: $message');
        ref.read(orderSavingProvider.notifier).state = false;
        Toast.error(context, 'Failed to save items: $message');
      },
    );
  }

  void _onGenerateBill() {
    // TODO: Implement bill generation API
    Toast.info(context, 'Bill generation coming soon');
  }

  Future<void> _onCancelItem(OrderItem item) async {
    final outletId = ApiEndpoints.defaultOutletId;

    final result = await showCancelItemDialog(
      context,
      item: item,
      outletId: outletId,
    );

    if (result == null || !mounted) return;

    // Call API to cancel item
    final apiItemId = int.tryParse(item.id);
    if (apiItemId == null) {
      Toast.error(context, 'Invalid item ID');
      return;
    }

    final apiResult = await ref
        .read(orderRepositoryProvider)
        .cancelItem(
          orderItemId: apiItemId,
          reason: result.reason,
          reasonId: result.reasonId,
          quantity: result.quantity,
        );

    if (!mounted) return;

    apiResult.when(
      success: (_, __) {
        // Optimistic local update
        ref
            .read(currentOrderProvider.notifier)
            .cancelItem(item.id, cancelQuantity: result.quantity);
        Toast.success(context, '${item.name} cancelled');

        // Re-fetch full table details from API to get accurate server totals
        _reloadOrderFromApi();
      },
      failure: (message, _, __) {
        Toast.error(context, 'Failed to cancel: $message');
      },
    );
  }

  /// Re-fetch table details from API and reload order with accurate server data
  Future<void> _reloadOrderFromApi() async {
    final tableId = int.tryParse(widget.tableId);
    if (tableId == null) return;

    final layoutRepo = ref.read(layoutRepositoryProvider);
    final result = await layoutRepo.getTableDetails(tableId);
    if (!mounted) return;

    result.whenOrNull(
      success: (details, _) {
        if (details.order != null) {
          final user = ref.read(currentUserProvider);
          ref
              .read(currentOrderProvider.notifier)
              .loadOrderFromTableDetails(
                tableDetails: details,
                captainId: user?.id.toString() ?? '',
                captainName: user?.name ?? '',
              );
          setState(() {
            _apiOrderId = details.order!.id;
          });
        }
      },
    );
  }

  Future<void> _onCancelOrder() async {
    final order = ref.read(currentOrderProvider);
    if (order == null || _apiOrderId == null) return;

    final outletId = ApiEndpoints.defaultOutletId;

    final result = await showCancelOrderDialog(
      context,
      orderNumber: order.id.length > 6
          ? order.id.substring(0, 6).toUpperCase()
          : order.id.toUpperCase(),
      outletId: outletId,
      orderTotal: order.grandTotal,
      itemCount: order.totalItems,
    );

    if (result == null || !mounted) return;

    // Call API to cancel order
    final apiResult = await ref
        .read(orderRepositoryProvider)
        .cancelOrder(
          orderId: _apiOrderId!,
          reason: result.reason,
          reasonId: result.reasonId,
        );

    if (!mounted) return;

    apiResult.when(
      success: (_, __) {
        Toast.success(context, 'Order cancelled');

        // Clear local order state
        ref.read(currentOrderProvider.notifier).clearOrder();

        // Update table status to available/cleaning
        ref
            .read(tablesProvider.notifier)
            .updateTableStatus(widget.tableId, TableStatus.available);

        // Refresh tables to get fresh data
        ref.read(tablesProvider.notifier).refresh();

        // Navigate back to table view
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      failure: (message, _, __) {
        Toast.error(context, 'Failed to cancel order: $message');
      },
    );
  }

  void _onItemTap(OrderItem item) {
    // Only allow editing pending items
    if (!item.canModify) {
      Toast.info(context, 'This item is locked (already sent to kitchen)');
      return;
    }
    _showItemEditSheet(item);
  }

  void _showItemEditSheet(OrderItem item) {
    // Look up the menu item data to show variants/addons
    final menuItemId = int.tryParse(item.menuItemId);
    final menuItem = menuItemId != null
        ? ref.read(menuItemProvider(menuItemId))
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ItemEditSheet(
          item: item,
          menuItem: menuItem,
          onUpdate:
              ({
                String? variantId,
                String? variantName,
                double? unitPrice,
                List<SelectedAddon>? addons,
                String? specialInstructions,
                int? quantity,
              }) {
                ref
                    .read(currentOrderProvider.notifier)
                    .updateItemDetails(
                      itemId: item.id,
                      variantId: variantId,
                      variantName: variantName,
                      unitPrice: unitPrice,
                      addons: addons,
                      specialInstructions: specialInstructions,
                      quantity: quantity,
                    );
                Navigator.pop(ctx);
                Toast.success(context, '${item.name} updated');
              },
          onRemove: () {
            ref.read(currentOrderProvider.notifier).removeItem(item.id);
            Navigator.pop(ctx);
            Toast.success(context, '${item.name} removed');
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

/// Bottom sheet for editing an order item's variant, addons, and instructions
class _ItemEditSheet extends StatefulWidget {
  final OrderItem item;
  final ApiMenuItem? menuItem;
  final Function({
    String? variantId,
    String? variantName,
    double? unitPrice,
    List<SelectedAddon>? addons,
    String? specialInstructions,
    int? quantity,
  })
  onUpdate;
  final VoidCallback onRemove;

  const _ItemEditSheet({
    required this.item,
    required this.onUpdate,
    required this.onRemove,
    this.menuItem,
  });

  @override
  State<_ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<_ItemEditSheet> {
  late TextEditingController _instructionsController;
  late int _quantity;
  ApiItemVariant? _selectedVariant;
  final Set<int> _selectedAddonIds = {};

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController(
      text: widget.item.specialInstructions ?? '',
    );
    _quantity = widget.item.quantity;

    // Pre-select current variant if menu item has variants
    if (widget.menuItem != null && widget.item.variantId != null) {
      final variantId = int.tryParse(widget.item.variantId!);
      if (variantId != null) {
        _selectedVariant = widget.menuItem!.variants?.firstWhere(
          (v) => v.id == variantId,
          orElse: () => widget.menuItem!.variants!.first,
        );
      }
    }

    // Pre-select current addons
    for (final addon in widget.item.addons) {
      final addonId = int.tryParse(addon.id);
      if (addonId != null) _selectedAddonIds.add(addonId);
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _currentPrice {
    double price = _selectedVariant?.price ?? widget.item.unitPrice;
    // Add selected addons price
    if (widget.menuItem != null) {
      for (final addon in widget.menuItem!.allAddons) {
        if (_selectedAddonIds.contains(addon.id)) {
          price += addon.price;
        }
      }
    } else {
      price += widget.item.addonsTotal;
    }
    return price * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = widget.menuItem?.variants?.isNotEmpty ?? false;
    final addonGroups = widget.menuItem?.addonGroups ?? [];

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Item name & remove
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove item',
                ),
              ],
            ),

            // Variants selector (from menu data)
            if (hasVariants) ...[
              const SizedBox(height: 12),
              const Text(
                'Select Variant',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.menuItem!.variants!.map((variant) {
                  final isSelected = variant.id == _selectedVariant?.id;
                  return ChoiceChip(
                    label: Text(
                      '${variant.name} - ₹${variant.price.toStringAsFixed(0)}',
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedVariant = variant);
                    },
                  );
                }).toList(),
              ),
            ],

            // Addon groups (from menu data)
            if (addonGroups.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...addonGroups.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (group.isRequired)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: group.addons.map((addon) {
                        final isSelected = _selectedAddonIds.contains(addon.id);
                        return FilterChip(
                          label: Text(
                            addon.price > 0
                                ? '${addon.name} +₹${addon.price.toStringAsFixed(0)}'
                                : addon.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                final selectedInGroup = group.addons
                                    .where(
                                      (a) => _selectedAddonIds.contains(a.id),
                                    )
                                    .length;
                                if (selectedInGroup < group.maxSelection) {
                                  _selectedAddonIds.add(addon.id);
                                }
                              } else {
                                _selectedAddonIds.remove(addon.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],

            // Show current addons as chips if no menu data available
            if (addonGroups.isEmpty && widget.item.addons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Add-ons',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.item.addons.map((addon) {
                  return Chip(
                    label: Text(
                      '${addon.name} (+₹${addon.price.toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    side: const BorderSide(
                      color: AppColors.success,
                      width: 0.5,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Quantity control
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQtyBtn(Icons.remove, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQtyBtn(Icons.add, () {
                  setState(() => _quantity++);
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Special instructions
            const Text(
              'Special Instructions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                hintText: 'e.g. Less spicy, no onion...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Price display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${_currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Update button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final instructions = _instructionsController.text.trim();
                  // Build addons list from selected addon IDs
                  List<SelectedAddon>? updatedAddons;
                  if (widget.menuItem != null) {
                    updatedAddons = widget.menuItem!.allAddons
                        .where((a) => _selectedAddonIds.contains(a.id))
                        .map(
                          (a) => SelectedAddon(
                            id: a.id.toString(),
                            name: a.name,
                            price: a.price,
                          ),
                        )
                        .toList();
                  }

                  widget.onUpdate(
                    variantId: _selectedVariant?.id.toString(),
                    variantName: _selectedVariant?.name,
                    unitPrice: _selectedVariant?.price,
                    addons: updatedAddons,
                    specialInstructions: instructions.isEmpty
                        ? null
                        : instructions,
                    quantity: _quantity,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Update Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _VariantSelectorSheet extends StatefulWidget {
  final ApiMenuItem item;
  final Function(ApiItemVariant?, List<ApiItemAddon>?) onSelect;

  const _VariantSelectorSheet({required this.item, required this.onSelect});

  @override
  State<_VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<_VariantSelectorSheet> {
  ApiItemVariant? _selectedVariant;
  final Set<int> _selectedAddonIds = {};

  @override
  void initState() {
    super.initState();
    final variants = widget.item.variants ?? [];
    if (variants.isNotEmpty) {
      _selectedVariant = variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      );
    }
  }

  List<ApiItemAddon> get _allAddons => widget.item.allAddons;

  List<ApiItemAddon> get _selectedAddons {
    return _allAddons.where((a) => _selectedAddonIds.contains(a.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          if ((widget.item.variants ?? []).isNotEmpty) ...[
            const Text(
              'Select Variant',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: (widget.item.variants ?? []).map((variant) {
                final isSelected = variant.id == _selectedVariant?.id;
                return ChoiceChip(
                  label: Text(
                    '${variant.name} - ₹${variant.price.toStringAsFixed(0)}',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedVariant = variant);
                  },
                );
              }).toList(),
            ),
          ],
          // Show addon groups with their options
          if ((widget.item.addonGroups ?? []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...(widget.item.addonGroups ?? []).map((group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (group.isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: group.addons.map((addon) {
                      final isSelected = _selectedAddonIds.contains(addon.id);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Veg/Non-veg indicator for addon
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: addon.isVeg
                                      ? AppColors.success
                                      : AppColors.error,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: addon.isVeg
                                        ? AppColors.success
                                        : AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Text(addon.name),
                            if (addon.price > 0)
                              Text(
                                ' +₹${addon.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              // Check max selection limit
                              final selectedInGroup = group.addons
                                  .where(
                                    (a) => _selectedAddonIds.contains(a.id),
                                  )
                                  .length;
                              if (selectedInGroup < group.maxSelection) {
                                _selectedAddonIds.add(addon.id);
                              }
                            } else {
                              _selectedAddonIds.remove(addon.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              );
            }),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: 'Add to Order',
            onPressed: () => widget.onSelect(_selectedVariant, _selectedAddons),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding a simple item (no variants/addons) with qty + notes
class _AddItemSheet extends StatefulWidget {
  final ApiMenuItem item;
  final Function(int quantity, String? instructions) onAdd;

  const _AddItemSheet({required this.item, required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _instructionsController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.price * _quantity;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Item name + veg indicator
            Row(
              children: [
                // Veg/Non-veg indicator
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.item.isVeg
                          ? AppColors.success
                          : AppColors.error,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.item.isVeg
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${widget.item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity control
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQtyBtn(Icons.remove, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQtyBtn(Icons.add, () {
                  setState(() => _quantity++);
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Special instructions
            const Text(
              'Special Instructions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                hintText: 'e.g. Less spicy, no onion...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Price display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Add Item button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final instructions = _instructionsController.text.trim();
                  widget.onAdd(
                    _quantity,
                    instructions.isEmpty ? null : instructions,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// Mobile order summary bar - clean, just shows items + total + view order
class _MobileOrderSummaryBar extends StatelessWidget {
  final int kotItemCount;
  final int pendingItemCount;
  final double total;
  final VoidCallback onViewOrder;

  const _MobileOrderSummaryBar({
    required this.kotItemCount,
    required this.pendingItemCount,
    required this.total,
    required this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = kotItemCount + pendingItemCount;

    return GestureDetector(
      onTap: onViewOrder,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Items count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalItems items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (pendingItemCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$pendingItemCount new',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                // Total
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View Order',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
