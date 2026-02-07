import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../domain/entities/entities.dart';
import 'providers/order_history_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ref.watch(orderHistoryScrollControllerProvider);
    final searchController = ref.watch(orderHistorySearchControllerProvider);
    final bannerUi = ref.watch(orderHistoryBannerUiProvider);
    final emptyUi = ref.watch(orderHistoryEmptyUiProvider);

    Future<void> refreshOrderHistory() async {
      await ref.read(orderHistoryProvider.notifier).refreshOrderHistory();
      await ref.read(orderHistoryProvider.notifier).loadOrderHistorySummary();
    }

    void onSearchChanged(String query) {
      ref.read(orderHistoryProvider.notifier).searchOrders(query);
    }

    final orders = ref.watch(ordersProvider);
    final isLoading = ref.watch(isOrderHistoryLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: refreshOrderHistory,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // Static Data Banner
            if (bannerUi != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bannerUi.message,
                          style: AppTextStyles.warning14SemiBold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(orderHistoryProvider.notifier).loadOrderHistory(refresh: true);
                          ref.read(orderHistoryProvider.notifier).loadOrderHistorySummary();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        tooltip: 'Retry API',
                      ),
                    ],
                  ),
                ),
              ),

            // // Summary Section
            // if (summary != null)
            //   SliverToBoxAdapter(
            //     child: _buildSummarySection(summary),
            //   ),

            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(searchController, onSearchChanged),
            ),

            // Compact Filter Button
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final orderHistoryState = ref.watch(orderHistoryProvider);
                  return _buildCompactFilterButton(context, orderHistoryState, ref, searchController);
                },
              ),
            ),

            // Orders List
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (orders.isEmpty)
              SliverFillRemaining(
                child: Consumer(
                  builder: (context, ref, child) => _buildEmptyState(emptyUi),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return Consumer(
                        builder: (context, ref, child) {
                          return _buildOrderCard(context, ref, orders[index]);
                        },
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(OrderHistorySummaryEntity summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sales Overview',
                style: AppTextStyles.white18Bold,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Total Orders',
                  summary.totalOrders.toString(),
                  Icons.receipt_long_rounded,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'Revenue',
                  summary.formattedRevenue,
                  Icons.currency_rupee_rounded,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Completed',
                  '${summary.completedOrders}',
                  Icons.check_circle_rounded,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'Cancelled',
                  '${summary.cancelledOrders}',
                  Icons.cancel_rounded,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.textOnPrimary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Completion Rate: ${summary.completionRate.toStringAsFixed(1)}%',
                  style: AppTextStyles.white13SemiBold,
                ),
                const Spacer(),
                Text(
                  'Avg: ${summary.formattedAverageOrderValue}',
                  style: AppTextStyles.white7013Medium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.white7011Medium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TextEditingController searchController, Function(String) onSearchChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, child) {
            return TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by order/table/customer/phone...',
                hintStyle: AppTextStyles.textSecondary14Regular,
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: onSearchChanged,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactFilterButton(
      BuildContext context,
      OrderHistoryState state,
      WidgetRef ref,
      TextEditingController searchController,
      ) {
    // Count active filters
    int activeFiltersCount = 0;
    if (state.selectedStatus != null) activeFiltersCount++;
    if (state.fromDate != null || state.toDate != null) activeFiltersCount++;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          // Filter Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFilterBottomSheet(context, state, ref, searchController),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeFiltersCount > 0
                          ? AppColors.primary
                          : AppColors.border,
                      width: activeFiltersCount > 0 ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeFiltersCount > 0
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: activeFiltersCount > 0
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: activeFiltersCount > 0
                              ? AppColors.textOnPrimary
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filters & Sorting',
                              style: AppTextStyles.primary14SemiBold,
                            ),
                            if (activeFiltersCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$activeFiltersCount filter${activeFiltersCount > 1 ? 's' : ''} active',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Clear All Button (if filters active)
          if (activeFiltersCount > 0) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  searchController.clear();
                  ref.read(orderHistoryProvider.notifier).clearFilters();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.clear_all_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
      BuildContext context,
      OrderHistoryState state,
      WidgetRef ref,
      TextEditingController searchController,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(orderHistoryProvider);
            const sortOptions = <String, String>{
              'createdAt': 'Date',
              'orderNumber': 'Order #',
              'totalAmount': 'Amount',
            };

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filters & Sorting',
                            style: AppTextStyles.primary20Bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Status Filter Section
                        _buildFilterSection(
                          'Order Status',
                          Icons.receipt_long_rounded,
                          Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildModernChip(
                                      'All',
                                      currentState.selectedStatus == null,
                                          () {
                                        searchController.clear();
                                        ref.read(orderHistoryProvider.notifier).clearFilters();
                                      },
                                      AppColors.primary,
                                      Icons.apps_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModernChip(
                                      'Running',
                                      currentState.selectedStatus == 'running',
                                          () => ref.read(orderHistoryProvider.notifier).filterByStatus('running'),
                                      AppColors.info,
                                      Icons.pending_actions_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModernChip(
                                      'Completed',
                                      currentState.selectedStatus == 'completed',
                                          () => ref.read(orderHistoryProvider.notifier).filterByStatus('completed'),
                                      AppColors.success,
                                      Icons.check_circle_outline_rounded,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModernChip(
                                      'Cancelled',
                                      currentState.selectedStatus == 'cancelled',
                                          () => ref.read(orderHistoryProvider.notifier).filterByStatus('cancelled'),
                                      AppColors.error,
                                      Icons.highlight_off_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sort Section
                        _buildFilterSection(
                          'Sort By',
                          Icons.sort_rounded,
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: sortOptions.containsKey(currentState.sortBy)
                                          ? currentState.sortBy
                                          : 'createdAt',
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.unfold_more_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      style: AppTextStyles.primary14SemiBold,
                                      items: sortOptions.entries
                                          .map(
                                            (e) => DropdownMenuItem<String>(
                                          value: e.key,
                                          child: Text(e.value),
                                        ),
                                      )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        ref.read(orderHistoryProvider.notifier).setSorting(
                                          sortBy: value,
                                          sortOrder: currentState.sortOrder,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final nextOrder = currentState.sortOrder.toLowerCase() == 'asc'
                                        ? 'desc'
                                        : 'asc';
                                    ref.read(orderHistoryProvider.notifier).setSorting(
                                      sortBy: currentState.sortBy,
                                      sortOrder: nextOrder,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      currentState.sortOrder.toLowerCase() == 'asc'
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick Date Filters
                        _buildFilterSection(
                          'Quick Date Filters',
                          Icons.calendar_today_rounded,
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateFilterButton(
                                  'Today',
                                  Icons.today_rounded,
                                      () {
                                    ref.read(orderHistoryProvider.notifier).loadTodayOrders();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDateFilterButton(
                                  'Week',
                                  Icons.date_range_rounded,
                                      () {
                                    ref.read(orderHistoryProvider.notifier).loadThisWeekOrders();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDateFilterButton(
                                  'Month',
                                  Icons.calendar_month_rounded,
                                      () {
                                    ref.read(orderHistoryProvider.notifier).loadThisMonthOrders();
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.primary14SemiBold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildCombinedFilterSection(
      OrderHistoryState state,
      WidgetRef ref,
      TextEditingController searchController,
      ) {
    const sortOptions = <String, String>{
      'createdAt': 'Date',
      'orderNumber': 'Order #',
      'totalAmount': 'Amount',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textOnPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Filters & Sorting',
                    style: AppTextStyles.primary16Bold,
                  ),
                ),
                if (state.selectedStatus != null ||
                    state.fromDate != null ||
                    state.toDate != null)
                  TextButton.icon(
                    onPressed: () {
                      searchController.clear();
                      ref.read(orderHistoryProvider.notifier).clearFilters();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // Status Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order Status',
                      style: AppTextStyles.primary14SemiBold,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModernChip(
                        'All',
                        state.selectedStatus == null,
                            () {
                          searchController.clear();
                          ref.read(orderHistoryProvider.notifier).clearFilters();
                        },
                        AppColors.primary,
                        Icons.apps_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        'Running',
                        state.selectedStatus == 'running',
                            () => ref.read(orderHistoryProvider.notifier).filterByStatus('running'),
                        AppColors.info,
                        Icons.pending_actions_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        'Completed',
                        state.selectedStatus == 'completed',
                            () => ref.read(orderHistoryProvider.notifier).filterByStatus('completed'),
                        AppColors.success,
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        'Cancelled',
                        state.selectedStatus == 'cancelled',
                            () => ref.read(orderHistoryProvider.notifier).filterByStatus('cancelled'),
                        AppColors.error,
                        Icons.highlight_off_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          ),

          // Sort & Date Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Sort Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sort By',
                            style: AppTextStyles.primary14SemiBold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: sortOptions.containsKey(state.sortBy) ? state.sortBy : 'createdAt',
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.unfold_more_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  style: AppTextStyles.primary14SemiBold,
                                  items: sortOptions.entries
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    ref.read(orderHistoryProvider.notifier).setSorting(
                                      sortBy: value,
                                      sortOrder: state.sortOrder,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final nextOrder = state.sortOrder.toLowerCase() == 'asc' ? 'desc' : 'asc';
                                ref.read(orderHistoryProvider.notifier).setSorting(
                                  sortBy: state.sortBy,
                                  sortOrder: nextOrder,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  state.sortOrder.toLowerCase() == 'asc'
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Date Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Filters',
                      style: AppTextStyles.primary14SemiBold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateFilterButton(
                        'Today',
                        Icons.today_rounded,
                            () => ref.read(orderHistoryProvider.notifier).loadTodayOrders(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateFilterButton(
                        'Week',
                        Icons.date_range_rounded,
                            () => ref.read(orderHistoryProvider.notifier).loadThisWeekOrders(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateFilterButton(
                        'Month',
                        Icons.calendar_month_rounded,
                            () => ref.read(orderHistoryProvider.notifier).loadThisMonthOrders(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChip(
      String label,
      bool isSelected,
      VoidCallback onTap,
      Color color,
      IconData icon,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            )
                : null,
            color: isSelected ? null : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.textOnPrimary : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(String label, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderHistoryEntity order) {
    final statusUi = ref.watch(orderStatusUiProvider(order.status));
    final dateFormatter = ref.watch(orderHistoryDateFormatterProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(context, ref, order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayOrderNumber,
                          style: AppTextStyles.primary16Bold,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.table_restaurant_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.displayTable,
                              style: AppTextStyles.textSecondary12Medium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusUi.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: AppTextStyles.white13SemiBold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (order.customerName != null)
                    _buildInfoRow(
                      Icons.person_rounded,
                      'Customer',
                      order.customerName!,
                      AppColors.textSecondary,
                    ),
                  if (order.customerName != null) const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.shopping_bag_rounded,
                    'Items',
                    '${order.itemsCountValue} item${order.itemsCountValue != 1 ? 's' : ''}',
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Time',
                    dateFormatter.format(order.createdAt),
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTextStyles.textSecondary14SemiBold,
                      ),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: AppTextStyles.primary20Bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTextStyles.textSecondary13Medium,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.primary13SemiBold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(OrderHistoryEmptyUi emptyUi) {
    return NoDataFound(
      icon: emptyUi.icon,
      title: emptyUi.title,
      subtitle: emptyUi.subtitle,
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, OrderHistoryState state) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: state.fromDate != null && state.toDate != null
          ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
          : null,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(orderHistoryProvider.notifier).filterByDateRange(picked.start, picked.end);
    }
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref, OrderHistoryEntity order) {
    final dateFormatter = ref.read(orderHistoryDateFormatterProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Consumer(
          builder: (context, ref, child) {
            final detailAsync = ref.watch(orderHistoryDetailProvider(order.id));

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Order Details',
                            style: AppTextStyles.primary20Bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: detailAsync.when(
                      loading: () => const Center(child: CustomLoader()),
                      error: (e, _) => NoDataFound(
                        icon: Icons.wifi_off_rounded,
                        title: 'Unable to load order details',
                        subtitle: 'Please try again.',
                        action: ElevatedButton(
                          onPressed: () => ref.invalidate(orderHistoryDetailProvider(order.id)),
                          child: const Text('Retry'),
                        ),
                      ),
                      data: (detail) => ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildDetailSection('Order Information', [
                            _buildDetailRow('Order Number', detail.displayOrderNumber),
                            _buildDetailRow('Table', detail.displayTable),
                            _buildDetailRow('Status', detail.displayStatus),
                            if (detail.customerName != null) _buildDetailRow('Customer', detail.customerName!),
                            _buildDetailRow('Date & Time', dateFormatter.format(detail.createdAt)),
                          ]),
                          const SizedBox(height: 20),
                          _buildDetailSection('Order Items', [
                            ...detail.items.map((item) => _buildItemTile(ref, item)),
                          ]),
                          const SizedBox(height: 20),
                          _buildDetailSection('Payment Summary', [
                            _buildDetailRow('Subtotal', '₹${detail.subtotal.toStringAsFixed(2)}'),
                            _buildDetailRow('Tax', '₹${detail.taxAmount.toStringAsFixed(2)}'),
                            _buildDetailRow('Discount', '₹${detail.discountAmount.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: AppTextStyles.primary16Bold,
                                ),
                                Text(
                                  '₹${detail.total.toStringAsFixed(2)}',
                                  style: AppTextStyles.primary16Bold,
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: AppTextStyles.primary16Bold,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.textSecondary14Medium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.primary14SemiBold,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(WidgetRef ref, OrderHistoryItemEntity item) {
    final statusUi = ref.watch(orderItemStatusUiProvider(item.status));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: AppTextStyles.primary14Bold,
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName!,
                    style: AppTextStyles.textSecondary12Regular,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusUi.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusUi.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: ${item.quantity}',
                style: AppTextStyles.textSecondary13SemiBold,
              ),
              const SizedBox(height: 4),
              Text(
                item.formattedSubtotal,
                style: AppTextStyles.primary16Bold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}