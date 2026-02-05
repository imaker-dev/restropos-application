import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../layout/data/repositories/layout_repository.dart';
import '../../data/models/table_details_model.dart';

/// Provider for fetching table details
final tableDetailsProvider = FutureProvider.family<TableDetailsResponse?, int>((ref, tableId) async {
  final repository = ref.watch(layoutRepositoryProvider);
  final result = await repository.getTableDetails(tableId);
  
  return result.when(
    success: (data, _) => data,
    failure: (_, __, ___) => null,
  );
});

/// Provider to store current table details for order screen navigation
final currentTableDetailsProvider = StateProvider<TableDetailsResponse?>((ref) => null);

/// Shows table details popup/bottom sheet based on device type
void showTableDetailsPopup(BuildContext context, int tableId, {VoidCallback? onViewOrder}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;
  
  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TableDetailsSheet(
        tableId: tableId,
        onViewOrder: onViewOrder,
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => TableDetailsDialog(
        tableId: tableId,
        onViewOrder: onViewOrder,
      ),
    );
  }
}

/// Table Details Bottom Sheet for mobile
class TableDetailsSheet extends ConsumerWidget {
  final int tableId;
  final VoidCallback? onViewOrder;

  const TableDetailsSheet({
    super.key,
    required this.tableId,
    this.onViewOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(tableDetailsProvider(tableId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Flexible(
            child: detailsAsync.when(
              data: (details) => details != null
                  ? _TableDetailsContent(
                      details: details,
                      onViewOrder: onViewOrder,
                    )
                  : const Center(child: Text('Failed to load table details')),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: LoadingIndicator(size: LoadingSize.large),
              ),
              error: (_, __) => const Center(child: Text('Error loading table details')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Table Details Dialog for tablet/desktop
class TableDetailsDialog extends ConsumerWidget {
  final int tableId;
  final VoidCallback? onViewOrder;

  const TableDetailsDialog({
    super.key,
    required this.tableId,
    this.onViewOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(tableDetailsProvider(tableId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Table Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: detailsAsync.when(
                data: (details) => details != null
                    ? _TableDetailsContent(
                        details: details,
                        onViewOrder: onViewOrder,
                      )
                    : const Center(child: Text('Failed to load table details')),
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: LoadingIndicator(size: LoadingSize.large),
                ),
                error: (_, __) => const Center(child: Text('Error loading table details')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main content widget for table details
class _TableDetailsContent extends ConsumerWidget {
  final TableDetailsResponse details;
  final VoidCallback? onViewOrder;

  const _TableDetailsContent({
    required this.details,
    this.onViewOrder,
  });

  Color get _statusColor {
    switch (details.status) {
      case 'available':
        return AppColors.tableAvailable;
      case 'occupied':
        return AppColors.tableOccupied;
      case 'running':
        return AppColors.tableRunning;
      case 'billing':
        return AppColors.tableBilling;
      case 'cleaning':
        return AppColors.tableCleaning;
      case 'blocked':
        return AppColors.tableBlocked;
      case 'reserved':
        return AppColors.tableReserved;
      default:
        return AppColors.tableAvailable;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header with status
          _buildTableHeader(),
          const SizedBox(height: 16),
          
          // Status summary message
          _buildStatusSummary(),
          const SizedBox(height: 16),
          
          // Session info (if active)
          if (details.session != null) ...[
            _buildSessionInfo(),
            const SizedBox(height: 16),
          ],
          
          // Captain info (if assigned)
          if (details.captain != null) ...[
            _buildCaptainInfo(),
            const SizedBox(height: 16),
          ],
          
          // Order info (if exists)
          if (details.order != null) ...[
            _buildOrderInfo(),
            const SizedBox(height: 16),
          ],
          
          // Items list (if has items)
          if (details.hasItems) ...[
            _buildItemsList(),
            const SizedBox(height: 16),
          ],
          
          // KOTs list (if has KOTs)
          if (details.hasKots) ...[
            _buildKotsList(),
            const SizedBox(height: 16),
          ],
          
          // Merged tables (if any)
          if (details.mergedTables.isNotEmpty) ...[
            _buildMergedTables(),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          _buildActionButtons(context, ref),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        // Table number badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            details.tableNumber,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Table info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${details.location.sectionName ?? 'Unknown'} • ${details.shape} • ${details.capacity} seats',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              details.statusSummary.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (details.status) {
      case 'available':
        return Icons.check_circle_outline;
      case 'occupied':
        return Icons.people;
      case 'running':
        return Icons.restaurant_menu;
      case 'billing':
        return Icons.receipt_long;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'blocked':
        return Icons.block;
      case 'reserved':
        return Icons.event_seat;
      default:
        return Icons.table_restaurant;
    }
  }

  Widget _buildSessionInfo() {
    final session = details.session!;
    return _buildInfoCard(
      title: 'Session Info',
      icon: Icons.timer,
      children: [
        _buildInfoRow('Guests', '${session.guestCount}'),
        if (session.guestName != null)
          _buildInfoRow('Guest Name', session.guestName!),
        _buildInfoRow('Duration', session.formattedDuration),
        if (session.notes != null)
          _buildInfoRow('Notes', session.notes!),
      ],
    );
  }

  Widget _buildCaptainInfo() {
    final captain = details.captain!;
    return _buildInfoCard(
      title: 'Captain',
      icon: Icons.person,
      children: [
        _buildInfoRow('Name', captain.name),
        if (captain.employeeCode != null)
          _buildInfoRow('Code', captain.employeeCode!),
      ],
    );
  }

  Widget _buildOrderInfo() {
    final order = details.order!;
    return _buildInfoCard(
      title: 'Current Order',
      icon: Icons.receipt,
      children: [
        _buildInfoRow('Order #', order.orderNumber),
        _buildInfoRow('Status', order.status.toUpperCase()),
        _buildInfoRow('Items', '${details.items.length}'),
        const Divider(height: 16),
        _buildInfoRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
        if (order.taxAmount > 0)
          _buildInfoRow('Tax', '₹${order.taxAmount.toStringAsFixed(2)}'),
        if (order.discountAmount > 0)
          _buildInfoRow('Discount', '-₹${order.discountAmount.toStringAsFixed(2)}'),
        _buildInfoRow(
          'Total',
          '₹${order.totalAmount.toStringAsFixed(2)}',
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return _buildInfoCard(
      title: 'Items (${details.items.length})',
      icon: Icons.fastfood,
      children: [
        ...details.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Veg/Non-veg indicator
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: item.isVeg ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.isVeg ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (item.hasAddons)
                      Text(
                        item.addons.map((a) => a.name).join(', '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'x${item.quantity.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${item.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildKotsList() {
    return _buildInfoCard(
      title: 'KOTs (${details.kots.length})',
      icon: Icons.receipt_long,
      children: [
        ...details.kots.map((kot) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getKotStatusColor(kot.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getKotStatusColor(kot.status).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getKotStatusIcon(kot.status),
                size: 16,
                color: _getKotStatusColor(kot.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kot.kotNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${kot.station ?? 'Kitchen'} • ${kot.itemCount} items',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getKotStatusColor(kot.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kot.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getKotStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'ready':
        return AppColors.success;
      case 'served':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getKotStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check;
      case 'ready':
        return Icons.done_all;
      case 'served':
        return Icons.check_circle;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildMergedTables() {
    return _buildInfoCard(
      title: 'Merged Tables',
      icon: Icons.merge_type,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: details.mergedTables.map((mt) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              mt.mergedTableNumber,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action based on status
        if (details.status == 'available') ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open table dialog
            },
            icon: const Icon(Icons.add),
            label: const Text('START TABLE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else if (details.hasActiveOrder) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Store table details for order screen to use
                    ref.read(currentTableDetailsProvider.notifier).state = details;
                    Navigator.of(context).pop();
                    onViewOrder?.call();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('VIEW ORDER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: View bill
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('BILL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.secondary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (details.status == 'cleaning') ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Mark as clean
            },
            icon: const Icon(Icons.check),
            label: const Text('MARK AS CLEAN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else if (details.status == 'blocked') ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Unblock table
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('UNBLOCK TABLE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else if (details.status == 'reserved') ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Seat reservation
            },
            icon: const Icon(Icons.event_seat),
            label: const Text('SEAT RESERVATION'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableReserved,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
