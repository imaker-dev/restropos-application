import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/entities.dart';
import 'providers/order_history_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).loadOrderHistory();
      ref.read(orderHistoryProvider.notifier).loadOrderHistorySummary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrderHistory() async {
    await ref.read(orderHistoryProvider.notifier).refreshOrderHistory();
    await ref.read(orderHistoryProvider.notifier).loadOrderHistorySummary();
  }

  void _onSearchChanged(String query) {
    ref.read(orderHistoryProvider.notifier).searchOrders(query);
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final summary = ref.watch(orderHistorySummaryProvider);
    final isLoading = ref.watch(isOrderHistoryLoadingProvider);
    final isUsingStaticData = ref.watch(isUsingStaticDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refreshOrderHistory,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Static Data Banner
            if (isUsingStaticData)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFFFCA5A5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Showing sample data - API unavailable',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(orderHistoryProvider.notifier).loadOrderHistory();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 20,
                        ),
                        tooltip: 'Retry API',
                      ),
                    ],
                  ),
                ),
              ),

            // Summary Section
            if (summary != null)
              SliverToBoxAdapter(
                child: _buildSummarySection(summary),
              ),

            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final orderHistoryState = ref.watch(orderHistoryProvider);
                  return _buildFilterChips(orderHistoryState);
                },
              ),
            ),

            // Quick Date Filters
            SliverToBoxAdapter(
              child: _buildQuickDateFilters(),
            ),

            // Orders List
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (orders.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildOrderCard(orders[index]);
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
          colors: [Color(0xFF1A365D), Color(0xFF2C5282)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A365D).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'Revenue',
                  summary.formattedRevenue,
                  Icons.currency_rupee_rounded,
                  const Color(0xFF34D399),
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
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'Cancelled',
                  '${summary.cancelledOrders}',
                  Icons.cancel_rounded,
                  const Color(0xFFF87171),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Completion Rate: ${summary.completionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Avg: ${summary.formattedAverageOrderValue}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by order number or customer...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade400),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildFilterChips(OrderHistoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                'All Orders',
                state.selectedStatus == null,
                    () => ref.read(orderHistoryProvider.notifier).filterByStatus(null),
                const Color(0xFF1A365D),
                Icons.list_alt_rounded,
              ),

              _buildChip(
                'Completed',
                state.selectedStatus == 'completed',
                    () => ref.read(orderHistoryProvider.notifier).filterByStatus('completed'),
                const Color(0xFF10B981),
                Icons.check_circle_rounded,
              ),
              _buildChip(
                'Cancelled',
                state.selectedStatus == 'cancelled',
                    () => ref.read(orderHistoryProvider.notifier).filterByStatus('cancelled'),
                const Color(0xFFEF4444),
                Icons.cancel_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, Color color, IconData icon) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Quick Date Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Today',
                  Icons.today_rounded,
                      () => ref.read(orderHistoryProvider.notifier).loadTodayOrders(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'This Week',
                  Icons.date_range_rounded,
                      () => ref.read(orderHistoryProvider.notifier).loadThisWeekOrders(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'This Month',
                  Icons.calendar_month_rounded,
                      () => ref.read(orderHistoryProvider.notifier).loadThisMonthOrders(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A365D),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildOrderCard(OrderHistoryEntity order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
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
                      color: const Color(0xFF1A365D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF1A365D),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.table_restaurant_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              order.displayTable,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer
                  if (order.customerName != null)
                    _buildInfoRow(
                      Icons.person_rounded,
                      'Customer',
                      order.customerName!,
                      Colors.grey.shade600,
                    ),

                  if (order.customerName != null) const SizedBox(height: 8),

                  // Items
                  _buildInfoRow(
                    Icons.shopping_bag_rounded,
                    'Items',
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                    Colors.grey.shade600,
                  ),

                  const SizedBox(height: 8),

                  // Time
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Time',
                    order.formattedDate,
                    Colors.grey.shade600,
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A365D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isUsingStaticData = ref.read(isUsingStaticDataProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUsingStaticData 
                  ? Icons.offline_bolt_rounded 
                  : Icons.receipt_long_rounded,
              size: 64,
              color: isUsingStaticData 
                  ? const Color(0xFFFCA5A5)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUsingStaticData 
                ? 'API Unavailable'
                : 'No Orders Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isUsingStaticData 
                  ? const Color(0xFF92400E)
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUsingStaticData 
                ? 'Showing sample data while API is unavailable'
                : 'Orders will appear here once created',
            style: TextStyle(
              fontSize: 14,
              color: isUsingStaticData 
                  ? const Color(0xFFFCA5A5)
                  : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (isUsingStaticData) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: const Color(0xFFFCA5A5),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tap retry to attempt API reconnection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'refunded':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange(BuildContext context, OrderHistoryState state) async {
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

  void _showOrderDetails(OrderHistoryEntity order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A365D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF1A365D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Order Info
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Order Information', [
                      _buildDetailRow('Order Number', order.displayOrderNumber),
                      _buildDetailRow('Table', order.displayTable),
                      _buildDetailRow('Status', order.displayStatus),
                      if (order.customerName != null)
                        _buildDetailRow('Customer', order.customerName!),
                      _buildDetailRow('Date & Time', order.formattedDate),
                    ]),

                    const SizedBox(height: 20),

                    _buildDetailSection('Order Items', [
                      ...order.items.map((item) => _buildItemTile(item)),
                    ]),

                    const SizedBox(height: 20),

                    _buildDetailSection('Payment Summary', [
                      _buildDetailRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
                      _buildDetailRow('Tax', '₹${order.taxAmount.toStringAsFixed(2)}'),
                      _buildDetailRow('Discount', '₹${order.discountAmount.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A365D),
                            ),
                          ),
                          Text(
                            '₹${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A365D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderHistoryItemEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A365D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: Color(0xFF1A365D),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getItemStatusColor(item.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getItemStatusColor(item.status),
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
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.formattedSubtotal,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A365D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getItemStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'served':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'refunded':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }
}