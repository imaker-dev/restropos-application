import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../menu/menu.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tables/tables.dart';
import '../providers/order_provider.dart';
import '../widgets/widgets.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String tableId;

  const OrderScreen({
    super.key,
    required this.tableId,
  });

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeOrder();
  }

  void _initializeOrder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final table = ref.read(tableProvider(widget.tableId));
      final user = ref.read(currentUserProvider);
      final existingOrder = ref.read(orderByTableProvider(widget.tableId));

      if (existingOrder != null) {
        ref.read(currentOrderProvider.notifier).loadOrder(existingOrder);
      } else if (table != null && user != null) {
        ref.read(currentOrderProvider.notifier).createOrder(
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

  void _onMenuItemTap(MenuItem item) {
    if (item.hasVariants) {
      _showVariantSelector(item);
    } else {
      ref.read(currentOrderProvider.notifier).addItem(item);
      Toast.success(context, '${item.name} added');
    }
  }

  void _showVariantSelector(MenuItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _VariantSelectorSheet(
        item: item,
        onSelect: (variant, addons) {
          ref.read(currentOrderProvider.notifier).addItem(
            item,
            variant: variant,
            addons: addons,
          );
          Navigator.pop(context);
          Toast.success(context, '${item.name} added');
        },
      ),
    );
  }

  void _onGenerateKot() {
    final order = ref.read(currentOrderProvider);
    final user = ref.read(currentUserProvider);
    if (order == null || user == null) return;

    final pendingItems = order.pendingItems;
    if (pendingItems.isEmpty) return;

    final kot = ref.read(kotsProvider.notifier).createKot(
      orderId: order.id,
      tableId: order.tableId,
      tableName: order.tableName,
      items: pendingItems,
      captainId: user.id.toString(),
      captainName: user.name,
    );

    ref.read(currentOrderProvider.notifier).markItemsAsKot(
      pendingItems.map((i) => i.id).toList(),
      kot.id,
    );

    // Update table status
    ref.read(tablesProvider.notifier).updateTableStatus(
      widget.tableId,
      TableStatus.runningKot,
    );

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
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const Flexible(
                      child: Text(
                        'Table Started By',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
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
                          ref.read(menuSearchQueryProvider.notifier).state = query;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SearchInput(
                        hint: 'Short Codes',
                        onChanged: (query) {
                          ref.read(menuSearchQueryProvider.notifier).state = query;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items grid
              Expanded(
                child: _buildMenuGrid(),
              ),
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
                color: AppColors.primary,
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
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
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
      body: Column(
        children: [
          // Search bar - Compact
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: SearchInput(
              controller: _searchController,
              hint: 'Search menu...',
              onChanged: (query) {
                ref.read(menuSearchQueryProvider.notifier).state = query;
              },
            ),
          ),
          // Categories - Scrollable
          const CategoryList(direction: Axis.horizontal),
          // Menu grid
          Expanded(child: _buildMenuGrid()),
          // Bottom order bar
          if (itemCount > 0)
            _MobileOrderBar(
              itemCount: itemCount,
              total: total,
              onViewOrder: _showOrderSheet,
              onKot: order?.hasPendingItems == true ? _onGenerateKot : null,
            ),
        ],
      ),
    );
  }

  void _showCustomerDialogMobile(BuildContext context) {
    final order = ref.read(currentOrderProvider);
    if (order == null) return;
    
    final nameController = TextEditingController(text: order.customerName ?? '');
    final phoneController = TextEditingController(text: order.customerPhone ?? '');

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
                      ref.read(currentOrderProvider.notifier).updateCustomerDetails(
                        name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
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
    final items = ref.watch(searchedMenuItemsProvider);

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
            return MenuItemCard(
              item: item,
              onTap: () => _onMenuItemTap(item),
            );
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
      ref.read(tablesProvider.notifier).updateRunningTotal(
        widget.tableId,
        order.grandTotal,
      );
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
  final MenuItem item;
  final Function(MenuItemVariant?, List<MenuItemAddon>?) onSelect;

  const _VariantSelectorSheet({
    required this.item,
    required this.onSelect,
  });

  @override
  State<_VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<_VariantSelectorSheet> {
  MenuItemVariant? _selectedVariant;
  final Set<String> _selectedAddonIds = {};

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.item.variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => widget.item.variants.first,
    );
  }

  List<MenuItemAddon> get _selectedAddons {
    return widget.item.addons
        .where((a) => _selectedAddonIds.contains(a.id))
        .toList();
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.item.variants.isNotEmpty) ...[
            const Text(
              'Select Variant',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: widget.item.variants.map((variant) {
                final isSelected = variant.id == _selectedVariant?.id;
                return ChoiceChip(
                  label: Text('${variant.name} - ₹${variant.price.toStringAsFixed(0)}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedVariant = variant);
                  },
                );
              }).toList(),
            ),
          ],
          if (widget.item.addons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Add-ons',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: widget.item.addons.map((addon) {
                final isSelected = _selectedAddonIds.contains(addon.id);
                return FilterChip(
                  label: Text('${addon.name} +₹${addon.price.toStringAsFixed(0)}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAddonIds.add(addon.id);
                      } else {
                        _selectedAddonIds.remove(addon.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
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

// Mobile bottom order bar - Shows item count, total, and quick actions
class _MobileOrderBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onViewOrder;
  final VoidCallback? onKot;

  const _MobileOrderBar({
    required this.itemCount,
    required this.total,
    required this.onViewOrder,
    this.onKot,
  });

  @override
  Widget build(BuildContext context) {
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
              // Order summary
              Expanded(
                child: GestureDetector(
                  onTap: onViewOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'View Order',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // KOT Button - Large and prominent
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onKot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onKot != null ? AppColors.success : AppColors.textHint,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'KOT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
