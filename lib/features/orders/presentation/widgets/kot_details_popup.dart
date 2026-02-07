import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';

/// Provider for fetching KOT details by ID
final kotDetailProvider = FutureProvider.family<ApiKot?, int>((
  ref,
  kotId,
) async {
  final repository = ref.watch(kotRepositoryProvider);
  final result = await repository.getKotById(kotId);
  return result.when(success: (data, _) => data, failure: (_, __, ___) => null);
});

/// Shows KOT details popup/bottom sheet based on device type
void showKotDetailsPopup(BuildContext context, int kotId, {WidgetRef? ref}) {
  // Invalidate to fetch fresh data
  ref?.invalidate(kotDetailProvider(kotId));

  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _KotDetailsSheet(kotId: kotId),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => _KotDetailsDialog(kotId: kotId),
    );
  }
}

/// KOT Details Bottom Sheet for mobile
class _KotDetailsSheet extends ConsumerWidget {
  final int kotId;

  const _KotDetailsSheet({required this.kotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(kotDetailProvider(kotId));

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
              data: (kot) => kot != null
                  ? _KotDetailsContent(kot: kot, kotId: kotId)
                  : const Center(child: Text('Failed to load KOT details')),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: LoadingIndicator(size: LoadingSize.large),
              ),
              error: (_, __) =>
                  const Center(child: Text('Error loading KOT details')),
            ),
          ),
        ],
      ),
    );
  }
}

/// KOT Details Dialog for tablet/desktop
class _KotDetailsDialog extends ConsumerWidget {
  final int kotId;

  const _KotDetailsDialog({required this.kotId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'preparing':
        return Colors.orange;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(kotDetailProvider(kotId));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 620,
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
          data: (kot) {
            if (kot == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Failed to load KOT details')),
              );
            }
            final color = _statusColor(kot.status);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored header bar
                _buildDialogHeader(context, kot, color),
                // Content
                Flexible(
                  child: _KotDetailsContent(
                    kot: kot,
                    kotId: kotId,
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
            child: Center(child: Text('Error loading KOT details')),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, ApiKot kot, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // KOT number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              kot.kotNumber,
              style: const TextStyle(
                fontSize: 18,
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
                Row(
                  children: [
                    Text(
                      kot.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (kot.priority > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGH PRIORITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${kot.station ?? 'Kitchen'} · ${kot.items.length} items · Order ${kot.orderNumber ?? '-'}',
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
}

/// Main content widget for KOT details
class _KotDetailsContent extends ConsumerStatefulWidget {
  final ApiKot kot;
  final int kotId;
  final bool isDesktopDialog;

  const _KotDetailsContent({
    required this.kot,
    required this.kotId,
    this.isDesktopDialog = false,
  });

  @override
  ConsumerState<_KotDetailsContent> createState() => _KotDetailsContentState();
}

class _KotDetailsContentState extends ConsumerState<_KotDetailsContent> {
  bool _isReprinting = false;
  StreamSubscription<Map<String, dynamic>>? _kotSub;
  StreamSubscription<Map<String, dynamic>>? _itemCancelledSub;

  @override
  void initState() {
    super.initState();
    _listenToKotUpdates();
    _listenToItemCancelled();
  }

  @override
  void dispose() {
    _kotSub?.cancel();
    _itemCancelledSub?.cancel();
    super.dispose();
  }

  void _listenToKotUpdates() {
    final wsService = ref.read(webSocketServiceProvider);
    _kotSub = wsService.kotUpdates.listen((data) {
      final kotId =
          data['kotId'] as int? ?? data['kot_id'] as int? ?? data['id'] as int?;
      if (kotId == widget.kotId) {
        ref.invalidate(kotDetailProvider(widget.kotId));
      }
    });
  }

  void _listenToItemCancelled() {
    final wsService = ref.read(webSocketServiceProvider);
    _itemCancelledSub = wsService.kotItemCancelled.listen((data) {
      final kotId = data['kotId'] as int? ?? data['kot_id'] as int?;
      if (kotId == widget.kotId) {
        ref.invalidate(kotDetailProvider(widget.kotId));
      }
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'preparing':
        return Colors.orange;
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check;
      case 'preparing':
        return Icons.restaurant;
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Future<void> _reprintKot() async {
    setState(() => _isReprinting = true);

    final repository = ref.read(kotRepositoryProvider);
    final result = await repository.reprintKot(widget.kotId);

    if (!mounted) return;

    result.when(
      success: (kot, _) {
        // Refresh provider with new data
        ref.invalidate(kotDetailProvider(widget.kotId));
        setState(() => _isReprinting = false);
        Toast.success(context, 'KOT reprinted successfully');
      },
      failure: (message, _, __) {
        setState(() => _isReprinting = false);
        Toast.error(context, 'Failed to reprint KOT: $message');
      },
    );
  }

  bool get _isDesktop => widget.isDesktopDialog;

  @override
  Widget build(BuildContext context) {
    final kot = widget.kot;
    if (_isDesktop) {
      return _buildDesktopLayout(kot);
    }
    return _buildMobileLayout(kot);
  }

  Widget _buildMobileLayout(ApiKot kot) {
    final color = _statusColor(kot.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KOT header with status badge
          _buildHeader(kot, color),
          const SizedBox(height: 16),

          // KOT info card
          _buildInfoCard(kot),
          const SizedBox(height: 16),

          // Timeline card
          _buildTimelineCard(kot),
          const SizedBox(height: 16),

          // Items list
          _buildItemsList(kot),
          const SizedBox(height: 16),

          // Notes
          if (kot.notes != null && kot.notes!.isNotEmpty) ...[
            _buildNotesCard(kot),
            const SizedBox(height: 16),
          ],

          // Reprint button
          _buildReprintButton(kot),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ApiKot kot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Info + Timeline side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoCard(kot)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimelineCard(kot)),
                  ],
                ),
                const SizedBox(height: 16),

                // Items list full width
                _buildItemsList(kot),

                // Notes
                if (kot.notes != null && kot.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(kot),
                ],
              ],
            ),
          ),
        ),
        // Reprint button pinned at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: _buildReprintButton(kot),
        ),
      ],
    );
  }

  Widget _buildHeader(ApiKot kot, Color color) {
    return Row(
      children: [
        // KOT number badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            kot.kotNumber,
            style: const TextStyle(
              fontSize: 18,
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
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(kot.status), size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      kot.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${kot.station ?? 'Kitchen'} • ${kot.items.length} items',
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

  BoxDecoration get _cardDecoration => BoxDecoration(
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
  );

  Widget _cardHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.all(_isDesktop ? 14 : 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
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
    );
  }

  Widget _buildInfoCard(ApiKot kot) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _cardHeader('KOT Information', Icons.info_outline),
          Padding(
            padding: EdgeInsets.all(_isDesktop ? 16 : 12),
            child: Column(
              children: [
                _infoRow('Order #', kot.orderNumber ?? '-'),
                _infoRow('Table', kot.tableNumber ?? '-'),
                _infoRow('Station', kot.station ?? 'Kitchen'),
                if (kot.priority > 0)
                  _infoRow('Priority', 'HIGH', valueColor: AppColors.error),
                _infoRow('Printed', '${kot.printedCount} time(s)'),
                if (kot.lastPrintedAt != null)
                  _infoRow('Last Printed', _formatDateTime(kot.lastPrintedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ApiKot kot) {
    final events = <_TimelineEntry>[];

    events.add(
      _TimelineEntry(
        'Created',
        _formatDateTime(kot.createdAt),
        Icons.add_circle_outline,
        AppColors.info,
      ),
    );

    if (kot.acceptedBy != null || kot.acceptedAt != null) {
      events.add(
        _TimelineEntry(
          'Accepted${kot.acceptedBy != null ? ' by ${kot.acceptedBy}' : ''}',
          _formatDateTime(kot.acceptedAt),
          Icons.check_circle_outline,
          AppColors.info,
        ),
      );
    }

    if (kot.readyAt != null) {
      events.add(
        _TimelineEntry(
          'Ready',
          _formatDateTime(kot.readyAt),
          Icons.done_all,
          AppColors.success,
        ),
      );
    }

    if (kot.servedAt != null) {
      events.add(
        _TimelineEntry(
          'Served${kot.servedBy != null ? ' by ${kot.servedBy}' : ''}',
          _formatDateTime(kot.servedAt),
          Icons.check_circle,
          AppColors.textSecondary,
        ),
      );
    }

    if (kot.cancelledAt != null) {
      events.add(
        _TimelineEntry(
          'Cancelled${kot.cancelledBy != null ? ' by ${kot.cancelledBy}' : ''}',
          _formatDateTime(kot.cancelledAt),
          Icons.cancel,
          AppColors.error,
        ),
      );
    }

    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _cardHeader('Timeline', Icons.timeline),
          Padding(
            padding: EdgeInsets.all(_isDesktop ? 16 : 12),
            child: Column(
              children: events
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: e.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(e.icon, size: 14, color: e.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  e.time,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ApiKot kot) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _cardHeader('Items (${kot.items.length})', Icons.fastfood),
          Padding(
            padding: EdgeInsets.all(_isDesktop ? 16 : 12),
            child: Column(
              children: kot.items.map((item) {
                final itemStatusColor = _statusColor(item.status ?? kot.status);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quantity badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: itemStatusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: itemStatusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.variant != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.variant!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (item.hasAddons) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.addonsText!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (item.hasInstructions) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '⊜ ${item.instructions}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.info,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Item status
                      if (item.status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: itemStatusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (item.status ?? '').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(ApiKot kot) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: _isDesktop
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kot.notes!,
              style: const TextStyle(fontSize: 13, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReprintButton(ApiKot kot) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isReprinting ? null : _reprintKot,
        icon: _isReprinting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.print),
        label: Text(_isReprinting ? 'Reprinting...' : 'REPRINT KOT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimelineEntry(this.label, this.time, this.icon, this.color);
}
