import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/app_preferences.dart';
import '../../core/constants/constants.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/utils/responsive_utils.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/menu/data/models/menu_models.dart';
import '../../features/menu/menu.dart' hide MenuItemType;
import '../../features/order_history/presentation/order_history_screen.dart';
import '../../features/report_history/report_history_screen.dart';
import '../../features/tables/tables.dart';
import '../../features/profile/presentation/profile_screen.dart';

class CaptainHomeScreen extends ConsumerStatefulWidget {
  const CaptainHomeScreen({super.key});

  @override
  ConsumerState<CaptainHomeScreen> createState() => _CaptainHomeScreenState();
}

class _CaptainHomeScreenState extends ConsumerState<CaptainHomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.table_restaurant, label: 'Tables'),
    _NavItem(icon: Icons.edit_note_sharp, label: 'Orders'),
    _NavItem(icon: Icons.dining, label: 'Menu'),
    _NavItem(icon: Icons.layers, label: 'Sales Report'),
    _NavItem(icon: Icons.history_toggle_off, label: 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return ResponsiveLayout(
      mobile: _buildMobileLayout(user),
      tablet: _buildTabletLayout(user),
      desktop: _buildDesktopLayout(user),
    );
  }

  Widget _buildDesktopLayout(ApiUser? user) {
    return Scaffold(
      body: Row(
        children: [
          // Left navigation rail
          _buildDesktopNavRail(user),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ApiUser? user) {
    return Scaffold(
      body: Row(
        children: [
          // Compact nav rail
          _buildTabletNavRail(user),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ApiUser? user) {
    // Clamp selected index for mobile (only 5 items in bottom nav)
    final mobileIndex = _selectedIndex.clamp(0, 4);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Row(
          children: [
            Text(
              _navItems[_selectedIndex].label,
              style: const TextStyle(fontSize: 16),
            ),
            // const SizedBox(width: 8),
            // const CompactConnectivityIndicator(),
          ],
        ),
        actions: [
          const ConnectivityIndicator(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: _showUserMenu,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: mobileIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 22,
        items: _navItems
            .take(5)
            .map(
              (item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildDesktopNavRail(ApiUser? user) {
    return Container(
      width: 200,
      color: AppColors.surface,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'RestroPOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          // User info with connectivity
          if (user != null)
            InkWell(
              onTap: _navigateToProfile,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: AppSpacing.paddingSm,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.roles.isNotEmpty
                                ? user.roles.first.name ?? 'Captain'
                                : 'Captain',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          // Connectivity indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: const ConnectivityIndicator(),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(),
          // Nav items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;
                return _DesktopNavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const Divider(),
          // Logout
          _DesktopNavItem(
            icon: Icons.logout,
            label: 'Logout',
            isSelected: false,
            onTap: _logout,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildTabletNavRail(ApiUser? user) {
    return Container(
      width: 72,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Connectivity indicator
          const CompactConnectivityIndicator(),
          const SizedBox(height: AppSpacing.sm),
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          // Nav items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;
                return _TabletNavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const Divider(),
          // Logout
          _TabletNavItem(
            icon: Icons.logout,
            label: 'Logout',
            isSelected: false,
            onTap: _logout,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return TableViewScreen(onTableSelected: _navigateToOrder);
      case 1:
        return _buildOrdersView();
      case 2:
        return _buildMenuView();
      case 3:
        return ReportHistoryScreen();
      case 4:
        return OrderHistoryScreen();
      // case 5:
      //   return _buildHistoryView();
      default:
        return TableViewScreen(onTableSelected: _navigateToOrder);
    }
  }

  Widget _buildOrdersView() {
    return _OrdersListView(
      onOrderTap: (tableId) {
        context.goNamed('order', pathParameters: {'tableId': tableId});
      },
    );
  }

  Widget _buildMenuView() {
    return const _MenuManagementView();
  }

  Widget _buildDeliveryView() {
    return _OrdersListView(
      filterType: 'delivery',
      onOrderTap: (tableId) {
        context.goNamed('order', pathParameters: {'tableId': tableId});
      },
    );
  }

  Widget _buildHistoryView() {
    return _OrdersListView(
      filterType: 'history',
      onOrderTap: (tableId) {
        context.goNamed('order', pathParameters: {'tableId': tableId});
      },
    );
  }



  void _navigateToOrder() {
    final selectedTableId = ref.read(selectedTableProvider);
    if (selectedTableId != null) {
      context.goNamed('order', pathParameters: {'tableId': selectedTableId});
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _showUserMenu() {
    final user = ref.read(currentUserProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                user?.name[0].toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.roles.isNotEmpty == true
                  ? (user!.roles.first.name ?? 'Captain')
                  : 'Captain',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async{
    await AppPreferences.clearSessionToken();
    await AppPreferences.clearUserId();
    ref.read(authProvider.notifier).logout();
    context.go('/login');
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _DesktopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabletNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Orders List View - Shows all active orders
class _OrdersListView extends ConsumerWidget {
  final String? filterType;
  final Function(String tableId) onOrderTap;

  const _OrdersListView({this.filterType, required this.onOrderTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider).tables;

    // Filter tables with active orders
    final activeTables = tables.where((t) {
      if (t.status == TableStatus.available) return false;
      if (filterType == 'delivery') return false; // TODO: Filter by order type
      if (filterType == 'history') return false;
      return true;
    }).toList();

    if (activeTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterType == 'delivery'
                  ? Icons.delivery_dining
                  : filterType == 'history'
                  ? Icons.shopping_bag
                  : Icons.receipt_long,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              filterType == 'delivery'
                  ? 'No delivery orders'
                  : filterType == 'history'
                  ? 'No order History'
                  : 'No active orders',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              Text(
                filterType == 'delivery'
                    ? 'Delivery Orders'
                    : filterType == 'history'
                    ? ' History'
                    : 'Active Orders',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${activeTables.length} orders',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Orders list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: activeTables.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final table = activeTables[index];
              return _OrderCard(
                table: table,
                onTap: () => onOrderTap(table.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const _OrderCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Table badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: table.status.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    table.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: table.status.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            table.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: table.status.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${table.guestCount ?? 0} guests',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getElapsedTime(table.orderStartedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(table.runningTotal ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getElapsedTime(DateTime? startTime) {
    if (startTime == null) return '--';
    final diff = DateTime.now().difference(startTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

// Menu Management View
class _MenuManagementView extends ConsumerStatefulWidget {
  const _MenuManagementView();

  @override
  ConsumerState<_MenuManagementView> createState() =>
      _MenuManagementViewState();
}

class _MenuManagementViewState extends ConsumerState<_MenuManagementView> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).loadMenu();
    });
  }

  List<ApiMenuItem> _getFilteredItems(List<ApiMenuItem> items, List<ApiCategory> categories) {
    if (_selectedCategoryIndex == 0) {
      return items;
    } else if (_selectedCategoryIndex < categories.length) {
      final selectedCategory = categories[_selectedCategoryIndex];
      return items.where((item) => item.categoryId == selectedCategory.id).toList();
    }
    return items;
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(menuItemsProvider);
    
     final allCategories = [
      const ApiCategory(id: -1, name: 'All', isActive: true),
      ...categories,
    ];
    final filteredItems = _getFilteredItems(items, allCategories);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              const Text(
                'Menu Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${filteredItems.length} items',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Categories tabs
        Container(
          height: 48,
          color: AppColors.scaffoldBackground,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: FilterChip(
                  label: Container(
                    constraints: BoxConstraints(
                      minHeight: 25,
                    ),
                    child: Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        category.name,
                        style: TextStyle(
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  selected: index == _selectedCategoryIndex,
                  onSelected: (_) => _onCategorySelected(index),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
              );
            },
          ),
        ),        // Menu items grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isMobile(context)? 2 : ResponsiveUtils.isTablet(context)?3:4,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.7,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                child: InkWell(
                  onTap: () => _showItemDetails(context, item),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.type == MenuItemType.veg
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const Spacer(),
                            if (item.hasVariants)
                              const Icon(
                                Icons.tune,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showItemDetails(BuildContext context, ApiMenuItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.type == MenuItemType.veg
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${item.categoryName}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Short Code: ${item.shortCode}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (item.hasVariants) ...[
              const SizedBox(height: 12),
              const Text(
                'Variants:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: (item.variants ?? [])
                    .map(
                      (v) => Chip(
                    label: Text(
                      '${v.name} - ₹${v.price.toStringAsFixed(0)}',
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
            if (item.addons?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text(
                'Add-ons:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: (item.addons ?? [])
                    .map(
                      (a) => Chip(
                    label: Text(
                      '${a.name} +₹${a.price.toStringAsFixed(0)}',
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Order History View
class _OrderHistoryView extends StatelessWidget {
  const _OrderHistoryView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: const Row(
            children: [
              Text(
                'Order History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Icon(Icons.filter_list, size: 20),
            ],
          ),
        ),
        const Divider(height: 1),
        // Empty state
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'No order history',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Completed orders will appear here',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
