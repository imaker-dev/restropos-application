import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../layout/data/repositories/layout_repository.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/presentation/widgets/cancel_order_dialog.dart';
import '../../../orders/presentation/widgets/kot_details_popup.dart';
import '../../data/models/table_details_model.dart';
import '../providers/tables_provider.dart';

/// Provider for fetching table details
final tableDetailsProvider = FutureProvider.family<TableDetailsResponse?, int>((
  ref,
  tableId,
) async {
  final repository = ref.watch(layoutRepositoryProvider);
  final result = await repository.getTableDetails(tableId);

  return result.when(success: (data, _) => data, failure: (_, __, ___) => null);
});

/// Provider to store current table details for order screen navigation
final currentTableDetailsProvider = StateProvider<TableDetailsResponse?>(
  (ref) => null,
);

/// Shows table details popup/bottom sheet based on device type
/// Always invalidates the provider to fetch fresh data
void showTableDetailsPopup(
  BuildContext context,
  int tableId, {
  VoidCallback? onViewOrder,
  WidgetRef? ref,
}) {
  // Invalidate the provider to fetch fresh data
  ref?.invalidate(tableDetailsProvider(tableId));

  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TableDetailsSheet(tableId: tableId, onViewOrder: onViewOrder),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) =>
          TableDetailsDialog(tableId: tableId, onViewOrder: onViewOrder),
    );
  }
}

/// Table Details Bottom Sheet for mobile
class TableDetailsSheet extends ConsumerWidget {
  final int tableId;
  final VoidCallback? onViewOrder;

  const TableDetailsSheet({super.key, required this.tableId, this.onViewOrder});

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
              error: (_, __) =>
                  const Center(child: Text('Error loading table details')),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: detailsAsync.when(
          data: (details) {
            if (details == null) {
              return const Center(child: Text('Failed to load table details'));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored header bar
                _buildDialogHeader(context, details),
                // Content
                Flexible(
                  child: _TableDetailsContent(
                    details: details,
                    onViewOrder: onViewOrder,
                    isDesktopDialog: true,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: LoadingIndicator(size: LoadingSize.large)),
          ),
          error: (_, __) => const SizedBox(
            height: 200,
            child: Center(child: Text('Error loading table details')),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
    BuildContext context,
    TableDetailsResponse details,
  ) {
    final statusColor = _getTableStatusColor(details.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Table number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              details.tableNumber,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${details.location.sectionName ?? 'Unknown'} · ${details.shape} · ${details.capacity} seats',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _getTableStatusColor(String status) {
    switch (status) {
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
}

/// Main content widget for table details
class _TableDetailsContent extends ConsumerStatefulWidget {
  final TableDetailsResponse details;
  final VoidCallback? onViewOrder;
  final bool isDesktopDialog;

  const _TableDetailsContent({
    required this.details,
    this.onViewOrder,
    this.isDesktopDialog = false,
  });

  @override
  ConsumerState<_TableDetailsContent> createState() =>
      _TableDetailsContentState();
}

class _TableDetailsContentState extends ConsumerState<_TableDetailsContent> {
  late TableDetailsResponse _details;
  StreamSubscription<Map<String, dynamic>>? _kotSub;
  StreamSubscription<Map<String, dynamic>>? _tableSub;
  StreamSubscription<Map<String, dynamic>>? _orderSub;
  StreamSubscription<Map<String, dynamic>>? _itemCancelledSub;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _details = widget.details;
    _listenToKotUpdates();
    _listenToTableAndOrderUpdates();
  }

  @override
  void didUpdateWidget(covariant _TableDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.details != oldWidget.details) {
      setState(() {
        _details = widget.details;
      });
    }
  }

  @override
  void dispose() {
    _kotSub?.cancel();
    _tableSub?.cancel();
    _orderSub?.cancel();
    _itemCancelledSub?.cancel();
    super.dispose();
  }

  /// Listen to table:updated, order:updated, and kot:item_cancelled events
  void _listenToTableAndOrderUpdates() {
    final wsService = ref.read(webSocketServiceProvider);

    _tableSub = wsService.tableUpdates.listen((data) {
      if (_isEventForThisTable(data)) {
        _refreshDetails();
      }
    });

    _orderSub = wsService.orderUpdates.listen((data) {
      if (_isEventForThisTable(data)) {
        _refreshDetails();
      }
    });

    _itemCancelledSub = wsService.kotItemCancelled.listen((data) {
      if (_isEventForThisTable(data)) {
        _refreshDetails();
      }
    });
  }

  /// Check if a WebSocket event belongs to this table
  bool _isEventForThisTable(Map<String, dynamic> data) {
    final tableId = data['tableId'] as int? ?? data['table_id'] as int?;
    if (tableId == _details.id) return true;

    // Also match by orderId if available
    final orderId = data['orderId'] as int? ?? data['order_id'] as int?;
    if (orderId != null && _details.order?.id == orderId) return true;

    return false;
  }

  /// Re-fetch table details from API without showing loading spinner
  Future<void> _refreshDetails() async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;

    try {
      final repository = ref.read(layoutRepositoryProvider);
      final result = await repository.getTableDetails(_details.id);
      if (!mounted) return;
      result.when(
        success: (data, _) {
          setState(() {
            _details = data;
          });
        },
        failure: (_, __, ___) {
          // Silently keep existing data
        },
      );
    } finally {
      _isRefreshing = false;
    }
  }

  void _listenToKotUpdates() {
    final wsService = ref.read(webSocketServiceProvider);
    _kotSub = wsService.kotUpdates.listen((data) {
      final kotId =
          data['kotId'] as int? ?? data['kot_id'] as int? ?? data['id'] as int?;
      final newStatus = data['status'] as String?;
      final tableId = data['tableId'] as int? ?? data['table_id'] as int?;

      // Match by KOT ID first
      final matchIndex = kotId != null
          ? _details.kots.indexWhere((k) => k.id == kotId)
          : -1;

      // Check if this event belongs to our table (by KOT match or tableId)
      final isForThisTable = matchIndex >= 0 || tableId == _details.id;

      if (!isForThisTable) return;

      // If we matched a KOT and have a status, do optimistic local update
      if (matchIndex >= 0 && newStatus != null) {
        setState(() {
          final updatedKots = List<TableKot>.from(_details.kots);
          final old = updatedKots[matchIndex];
          updatedKots[matchIndex] = TableKot(
            id: old.id,
            kotNumber: old.kotNumber,
            status: newStatus,
            station: old.station,
            itemCount: old.itemCount,
            totalItemCount: old.totalItemCount,
            cancelledItemCount: old.cancelledItemCount,
            priority: old.priority,
            acceptedBy:
                (data['acceptedBy'] as String?) ??
                (data['accepted_by'] as String?) ??
                old.acceptedBy,
            acceptedAt: old.acceptedAt,
            readyAt: old.readyAt,
            servedAt: old.servedAt,
            createdAt: old.createdAt,
          );
          _details = TableDetailsResponse(
            id: _details.id,
            tableNumber: _details.tableNumber,
            name: _details.name,
            status: _details.status,
            capacity: _details.capacity,
            minCapacity: _details.minCapacity,
            shape: _details.shape,
            isMergeable: _details.isMergeable,
            isSplittable: _details.isSplittable,
            qrCode: _details.qrCode,
            location: _details.location,
            position: _details.position,
            session: _details.session,
            captain: _details.captain,
            order: _details.order,
            items: _details.items,
            kots: updatedKots,
            billing: _details.billing,
            timeline: _details.timeline,
            mergedTables: _details.mergedTables,
            statusSummary: _details.statusSummary,
          );
        });
      }

      // Always do a full refresh to get complete updated data from API
      _refreshDetails();
    });
  }

  TableDetailsResponse get details => _details;

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

  bool get _isDesktop => widget.isDesktopDialog;

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
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

  Widget _buildDesktopLayout() {
    final hasSessionOrCaptain =
        details.session != null || details.captain != null;
    final hasOrderOrItems = details.order != null || details.hasItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status summary
                _buildStatusSummary(),
                const SizedBox(height: 16),

                // Row 1: Session + Captain side by side
                if (hasSessionOrCaptain) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.session != null)
                        Expanded(child: _buildSessionInfo()),
                      if (details.session != null && details.captain != null)
                        const SizedBox(width: 16),
                      if (details.captain != null)
                        Expanded(child: _buildCaptainInfo()),
                      // If only one exists, add spacer
                      if (details.session != null && details.captain == null)
                        const Expanded(child: SizedBox()),
                      if (details.session == null && details.captain != null)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Row 2: Order info + KOTs side by side
                if (hasOrderOrItems || details.hasKots) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.order != null)
                        Expanded(child: _buildOrderInfo()),
                      if (details.order != null && details.hasKots)
                        const SizedBox(width: 16),
                      if (details.hasKots) Expanded(child: _buildKotsList()),
                      // If only one exists, add spacer
                      if (details.order != null && !details.hasKots)
                        const Expanded(child: SizedBox()),
                      if (details.order == null && details.hasKots)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Items list full width
                if (details.hasItems) ...[
                  _buildItemsList(),
                  const SizedBox(height: 16),
                ],

                // Merged tables full width
                if (details.mergedTables.isNotEmpty) ...[
                  _buildMergedTables(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        // Action buttons pinned at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: _buildActionButtons(context, ref),
        ),
      ],
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
          Icon(_getStatusIcon(), color: _statusColor, size: 20),
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
        if (session.notes != null) _buildInfoRow('Notes', session.notes!),
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
          _buildInfoRow(
            'Discount',
            '-₹${order.discountAmount.toStringAsFixed(2)}',
          ),
        _buildInfoRow(
          'Total',
          '₹${order.totalAmount.toStringAsFixed(2)}',
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    final cancelledCount = details.items
        .where((i) => i.status == 'cancelled')
        .length;
    return _buildInfoCard(
      title:
          'Items (${details.items.length})${cancelledCount > 0 ? ' • $cancelledCount cancelled' : ''}',
      icon: Icons.fastfood,
      children: [
        ...details.items.map((item) {
          final isCancelled = item.status == 'cancelled';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Opacity(
              opacity: isCancelled ? 0.55 : 1.0,
              child: Row(
                children: [
                  // Veg/Non-veg indicator
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCancelled
                            ? AppColors.error
                            : item.isVeg
                            ? Colors.green
                            : Colors.red,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: isCancelled
                          ? Icon(Icons.close, size: 10, color: AppColors.error)
                          : Container(
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
                          style: TextStyle(
                            fontSize: 13,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.error,
                            color: isCancelled ? AppColors.textSecondary : null,
                          ),
                        ),
                        if (item.hasAddons)
                          Text(
                            item.addons.map((a) => a.name).join(', '),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCancelled)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'CANCELLED',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  Text(
                    'x${item.quantity.toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.error,
                      color: isCancelled ? AppColors.textSecondary : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.error,
                      color: isCancelled ? AppColors.textSecondary : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildKotsList() {
    return _buildInfoCard(
      title: 'KOTs (${details.kots.length})',
      icon: Icons.receipt_long,
      children: [
        ...details.kots.map(
          (kot) => GestureDetector(
            onTap: () => showKotDetailsPopup(context, kot.id, ref: ref),
            child: Container(
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
                          '${kot.station ?? 'kitchen'} • ${kot.itemCount} items${kot.hasCancelledItems ? ' (${kot.cancelledItemCount} cancelled)' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: kot.isCancelled
                                ? AppColors.error.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
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
      case 'cancelled':
        return AppColors.error;
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
      case 'cancelled':
        return Icons.cancel;
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
          children: details.mergedTables
              .map(
                (mt) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                ),
              )
              .toList(),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: _isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(_isDesktop ? 14 : 12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _isDesktop ? 15 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(_isDesktop ? 16 : 12),
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

  Future<void> _onCancelOrder(BuildContext context, WidgetRef ref) async {
    final order = _details.order;
    if (order == null) return;

    final outletId = ApiEndpoints.defaultOutletId;

    final result = await showCancelOrderDialog(
      context,
      orderNumber: order.orderNumber,
      outletId: outletId,
      orderTotal: order.totalAmount,
      itemCount: _details.items.length,
    );

    if (result == null || !mounted) return;

    // Call API to cancel order
    final apiResult = await ref
        .read(orderRepositoryProvider)
        .cancelOrder(
          orderId: order.id,
          reason: result.reason,
          reasonId: result.reasonId,
        );

    if (!mounted) return;

    apiResult.when(
      success: (_, __) {
        Toast.success(context, 'Order cancelled');

        // Refresh tables to get fresh data
        ref.read(tablesProvider.notifier).refresh();

        // Close popup
        Navigator.of(context).pop();
      },
      failure: (message, _, __) {
        Toast.error(context, 'Failed to cancel order: $message');
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    // Check if table is occupied/running but has no order
    final isOccupiedWithoutOrder =
        (details.status == 'occupied' || details.status == 'running') &&
        details.session != null &&
        !details.hasActiveOrder;

    // Check if this table belongs to another captain
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id?.toString();
    final isOwnedByAnotherCaptain =
        details.captain != null &&
        currentUserId != null &&
        details.captain!.id.toString() != currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show warning if managed by another captain
        if (isOwnedByAnotherCaptain) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Managed by ${details.captain!.name}. Take transfer permission from manager to access this order.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Primary action based on status
        if (details.status == 'available' || details.status.isEmpty) ...[
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
        ] else if (isOccupiedWithoutOrder && !isOwnedByAnotherCaptain) ...[
          // Occupied table with session but no order - show TAKE ORDER button
          ElevatedButton.icon(
            onPressed: () {
              // Store table details for order screen to use
              ref.read(currentTableDetailsProvider.notifier).state = details;
              Navigator.of(context).pop();
              widget.onViewOrder?.call();
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('TAKE ORDER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ] else if (details.hasActiveOrder && !isOwnedByAnotherCaptain) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Store table details for order screen to use
                    ref.read(currentTableDetailsProvider.notifier).state =
                        details;
                    Navigator.of(context).pop();
                    widget.onViewOrder?.call();
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
                    side: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Cancel order button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _onCancelOrder(context, ref),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('CANCEL ORDER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ] else if (details.hasActiveOrder && isOwnedByAnotherCaptain) ...[
          // Another captain's order - no action buttons, just the warning above
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
        ] else if (details.status == 'reserved' &&
            !isOwnedByAnotherCaptain) ...[
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
        // If another captain owns a reserved table, show nothing extra
      ],
    );
  }
}
