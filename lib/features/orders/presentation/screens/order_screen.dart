import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../menu/data/models/menu_models.dart';
import '../../../menu/menu.dart' hide MenuItemType;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tables/tables.dart';
import '../providers/order_provider.dart';
import '../widgets/widgets.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String tableId;

  const OrderScreen({super.key, required this.tableId});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final _searchController = TextEditingController();
  bool _isCategorySidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeOrder();
  }

  void _initializeOrder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load menu from API
      ref.read(menuProvider.notifier).loadMenu();

      final table = ref.read(tableProvider(widget.tableId));
      final user = ref.read(currentUserProvider);
      final tableDetails = ref.read(currentTableDetailsProvider);
      final existingOrder = ref.read(orderByTableProvider(widget.tableId));

      // Priority: 1. API table details, 2. Local existing order, 3. Create new
      if (tableDetails != null && tableDetails.hasActiveOrder && user != null) {
        // Load order from API table details (existing order with items)
        ref.read(currentOrderProvider.notifier).loadOrderFromTableDetails(
          tableDetails: tableDetails,
          captainId: user.id.toString(),
          captainName: user.name,
        );
        // Clear the table details after loading
        ref.read(currentTableDetailsProvider.notifier).state = null;
      } else if (existingOrder != null) {
        ref.read(currentOrderProvider.notifier).loadOrder(existingOrder);
      } else if (table != null && user != null) {
        ref
            .read(currentOrderProvider.notifier)
            .createOrder(
          tableId: table.id,
          tableName: table.name,
          captainId: user.id.toString(),
          captainName: user.name,
          guestCount: table.guestCount ?? 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMenuItemTap(ApiMenuItem item) {
    // Show selector sheet if item has variants OR addons
    if (item.hasVariants || item.hasAddons) {
      _showVariantSelector(item);
    } else {
      ref.read(currentOrderProvider.notifier).addItem(item);
      Toast.success(context, '${item.name} added');
    }
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

  void _onGenerateKot() {
    final order = ref.read(currentOrderProvider);
    final user = ref.read(currentUserProvider);
    if (order == null || user == null) return;

    final pendingItems = order.pendingItems;
    if (pendingItems.isEmpty) return;

    final kot = ref
        .read(kotsProvider.notifier)
        .createKot(
      orderId: order.id,
      tableId: order.tableId,
      tableName: order.tableName,
      items: pendingItems,
      captainId: user.id.toString(),
      captainName: user.name,
    );

    ref
        .read(currentOrderProvider.notifier)
        .markItemsAsKot(pendingItems.map((i) => i.id).toList(), kot.id);

    // Update table status
    ref
        .read(tablesProvider.notifier)
        .updateTableStatus(widget.tableId, TableStatus.running);

    Toast.success(context, 'KOT #${kot.kotNumber} generated');
  }

  @override
  Widget build(BuildContext context) {
    final table = ref.watch(tableProvider(widget.tableId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(table),
      ),
    );
  }

  Widget _buildDesktopLayout(table) {
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
              // Search bar
              Container(
                padding: AppSpacing.paddingSm,
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: SearchInput(
                        controller: _searchController,
                        hint: 'Search Item',
                        onChanged: (query) {
                          ref.read(menuSearchQueryProvider.notifier).state =
                              query;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SearchInput(
                        hint: 'Short Codes',
                        onChanged: (query) {
                          ref.read(menuSearchQueryProvider.notifier).state =
                              query;
                        },
                      ),
                    ),
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
            onSaveAndPrint: () => _saveAndPrint(),
            onKot: _onGenerateKot,
            onKotPrint: () {
              _onGenerateKot();
              // TODO: Print KOT
            },
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
            onKot: _onGenerateKot,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final order = ref.watch(currentOrderProvider);
    final table = ref.watch(tableProvider(widget.tableId));
    final itemCount = order?.totalItems ?? 0;
    final total = order?.grandTotal ?? 0;
    final kotItemCount = order?.items.where((i) => !i.canModify).length ?? 0;
    final pendingItemCount = order?.pendingItems.length ?? 0;

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
          if (itemCount > 0)
            Container(
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
                        controller: _searchController,
                        hint: 'Search menu...',
                        onChanged: (query) {
                          ref.read(menuSearchQueryProvider.notifier).state = query;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Categories - Horizontal (shown when sidebar closed)
              if (!_isCategorySidebarOpen)
                const CategoryList(direction: Axis.horizontal),
              // Menu grid
              Expanded(child: _buildMenuGrid()),
              // Order summary bar (shows KOT items count if any)
              if (kotItemCount > 0 || pendingItemCount > 0)
                _MobileOrderSummaryBar(
                  kotItemCount: kotItemCount,
                  pendingItemCount: pendingItemCount,
                  total: total,
                  onViewOrder: _showOrderSheet,
                  onKot: pendingItemCount > 0 ? _onGenerateKot : null,
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
                          const Icon(Icons.restaurant_menu,
                              color: Colors.white, size: 20),
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
                            child: const Icon(Icons.close,
                                color: Colors.white70, size: 18),
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

  Widget _buildMenuGrid() {
    final menuState = ref.watch(menuProvider);
    final items = ref.watch(searchedMenuItemsProvider);

    // Show loading indicator
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              onPressed: () => ref.read(menuProvider.notifier).loadMenu(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(color: AppColors.textSecondary),
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => OrderSummaryPanel(
          onSave: () {
            _saveOrder();
            Navigator.pop(context);
          },
          onKot: () {
            _onGenerateKot();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _saveOrder() {
    final order = ref.read(currentOrderProvider);
    if (order != null) {
      ref.read(ordersProvider.notifier).addOrder(order);
      ref
          .read(tablesProvider.notifier)
          .updateRunningTotal(widget.tableId, order.grandTotal);
      Toast.success(context, 'Order saved');
    }
  }

  void _saveAndPrint() {
    _saveOrder();
    // TODO: Implement print functionality
    Toast.info(context, 'Print functionality coming soon');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
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

// Enhanced mobile order summary bar - Shows KOT items vs pending items
class _MobileOrderSummaryBar extends StatelessWidget {
  final int kotItemCount;
  final int pendingItemCount;
  final double total;
  final VoidCallback onViewOrder;
  final VoidCallback? onKot;

  const _MobileOrderSummaryBar({
    required this.kotItemCount,
    required this.pendingItemCount,
    required this.total,
    required this.onViewOrder,
    this.onKot,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = kotItemCount + pendingItemCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Order summary with KOT/Pending breakdown
              Expanded(
                child: GestureDetector(
                  onTap: onViewOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Item counts
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                // Total items badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$totalItems items',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // KOT sent indicator
                                if (kotItemCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.warning,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          size: 10,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$kotItemCount KOT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Pending items info
                            if (pendingItemCount > 0)
                              Text(
                                '$pendingItemCount new items to send',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        // Total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // KOT Button - Only enabled if there are pending items
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onKot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onKot != null
                        ? AppColors.success
                        : AppColors.textHint,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'KOT',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (pendingItemCount > 0)
                        Text(
                          '($pendingItemCount)',
                          style: const TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
