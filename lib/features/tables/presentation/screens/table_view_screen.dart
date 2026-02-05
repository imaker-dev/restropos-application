import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../layout/data/models/layout_models.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/tables_provider.dart';
import '../widgets/widgets.dart';

class TableViewScreen extends ConsumerWidget {
  final VoidCallback? onTableSelected;

  const TableViewScreen({super.key, this.onTableSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesGrouped = ref.watch(tablesGroupedBySectionProvider);
    final tableCounts = ref.watch(tableCountsProvider);
    final selectedTableId = ref.watch(selectedTableProvider);
    final isLoading = ref.watch(tablesProvider).isLoading;

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return Column(
          children: [
            // Header with actions
            _buildHeader(context, ref, tableCounts, deviceType),
            // Status Legend - Always visible for Captain
            _buildStatusLegend(context, ref, tableCounts, deviceType),
            const Divider(height: 1),
            // Table grid
            Expanded(
              child: isLoading
                  ? const Center(
                      child: LoadingIndicator(size: LoadingSize.large),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(tablesProvider.notifier).refresh(),
                      child: CustomScrollView(
                        slivers: [
                          for (final entry in tablesGrouped.entries) ...[
                            SliverToBoxAdapter(
                              child: SectionHeader(
                                title: entry.key,
                                tableCount: entry.value.length,
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _getCrossAxisCount(
                                        deviceType,
                                      ),
                                      crossAxisSpacing: AppSpacing.xs,
                                      mainAxisSpacing: AppSpacing.xs,
                                      childAspectRatio: 1,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final table = entry.value[index];
                                  return TableCard(
                                    table: table,
                                    isSelected: table.id == selectedTableId,
                                    onTap: () => _onTableTap(
                                      context,
                                      ref,
                                      table,
                                      deviceType,
                                    ),
                                    onLongPress: () =>
                                        _onTableLongPress(context, ref, table),
                                  );
                                }, childCount: entry.value.length),
                              ),
                            ),
                          ],
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    Map<TableStatus, int> counts,
    DeviceType deviceType,
  ) {
    final isMobile = deviceType.isMobile;
    final floorsAsync = ref.watch(floorsProvider);
    final selectedFloorId = ref.watch(selectedFloorProvider);

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Floor Dropdown
          floorsAsync.when(
            data: (floors) {
              if (floors.isEmpty) {
                return Text(
                  'Table View',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                );
              }

              // If multiple floors, show dropdown
              if (floors.length > 1) {
                // Auto-load first floor if none selected
                if (selectedFloorId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedFloorProvider.notifier).state =
                        floors.first.id;
                    ref
                        .read(tablesProvider.notifier)
                        .loadTablesByFloorDetails(floors.first.id);
                    // Join WebSocket floor room for real-time updates
                    final outletId = ref.read(outletIdProvider);
                    ref
                        .read(webSocketServiceProvider)
                        .joinFloorRoom(outletId, floors.first.id);
                  });
                }
                return _FloorDropdown(
                  floors: floors,
                  selectedFloorId: selectedFloorId ?? floors.first.id,
                  onChanged: (floorId) {
                    ref.read(selectedFloorProvider.notifier).state = floorId;
                    if (floorId != null) {
                      ref
                          .read(tablesProvider.notifier)
                          .loadTablesByFloorDetails(floorId);
                      // Join WebSocket floor room for real-time updates
                      final outletId = ref.read(outletIdProvider);
                      ref
                          .read(webSocketServiceProvider)
                          .joinFloorRoom(outletId, floorId);
                    }
                  },
                );
              }

              // Single floor - auto-load tables and show name
              if (selectedFloorId == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedFloorProvider.notifier).state =
                      floors.first.id;
                  ref
                      .read(tablesProvider.notifier)
                      .loadTablesByFloorDetails(floors.first.id);
                  // Join WebSocket floor room for real-time updates
                  final outletId = ref.read(outletIdProvider);
                  ref
                      .read(webSocketServiceProvider)
                      .joinFloorRoom(outletId, floors.first.id);
                });
              }
              return Text(
                floors.first.name,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              );
            },
            loading: () =>
                const SizedBox(width: 100, child: LinearProgressIndicator()),
            error: (_, __) => Text(
              'Table View',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Connection status indicator
          Consumer(
            builder: (context, ref, _) {
              final isConnected = ref.watch(isSocketConnectedProvider);
              return Tooltip(
                message: isConnected
                    ? 'Real-time connected'
                    : 'Reconnecting...',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Live' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // const SizedBox(width: 8),
          // // Compact buttons for mobile
          // _CompactButton(
          //   label: 'Delivery',
          //   color: AppColors.info,
          //   onPressed: () {},
          // ),
          // const SizedBox(width: 4),
          // _CompactButton(
          //   label: 'Pick Up',
          //   color: AppColors.secondary,
          //   onPressed: () {},
          // ),
          const SizedBox(width: 4),
          _CompactButton(
            label: '+ Add',
            color: AppColors.primary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(
    BuildContext context,
    WidgetRef ref,
    Map<TableStatus, int> counts,
    DeviceType deviceType,
  ) {
    final selectedStatus = ref.watch(selectedStatusFilterProvider);

    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All tables option
            _StatusDot(
              color: AppColors.textSecondary,
              label: 'All',
              count: counts.values.fold(0, (a, b) => a + b),
              isSelected: selectedStatus == null,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state = null,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableAvailable,
              label: 'Available',
              count: counts[TableStatus.available] ?? 0,
              isSelected: selectedStatus == TableStatus.available,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.available,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableOccupied,
              label: 'Occupied',
              count: counts[TableStatus.occupied] ?? 0,
              isSelected: selectedStatus == TableStatus.occupied,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.occupied,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableRunning,
              label: 'Running',
              count: counts[TableStatus.running] ?? 0,
              isSelected: selectedStatus == TableStatus.running,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.running,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableBilling,
              label: 'Billing',
              count: counts[TableStatus.billing] ?? 0,
              isSelected: selectedStatus == TableStatus.billing,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.billing,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableCleaning,
              label: 'Cleaning',
              count: counts[TableStatus.cleaning] ?? 0,
              isSelected: selectedStatus == TableStatus.cleaning,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.cleaning,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableBlocked,
              label: 'Blocked',
              count: counts[TableStatus.blocked] ?? 0,
              isSelected: selectedStatus == TableStatus.blocked,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.blocked,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusDot(
              color: AppColors.tableReserved,
              label: 'Reserved',
              count: counts[TableStatus.reserved] ?? 0,
              isSelected: selectedStatus == TableStatus.reserved,
              onTap: () =>
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      TableStatus.reserved,
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 4;
      case DeviceType.tablet:
        return 6;
      case DeviceType.desktop:
        return 10;
    }
  }

  void _onTableTap(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    DeviceType deviceType,
  ) {
    HapticFeedback.selectionClick();
    ref.read(selectedTableProvider.notifier).state = table.id;

    if (table.status == TableStatus.available) {
      // For available table, show quick open dialog
      _showOpenTableDialog(context, ref, table);
    } else {
      // For non-available tables, show detailed table popup
      // Pass ref to invalidate cache and fetch fresh data
      showTableDetailsPopup(
        context,
        int.tryParse(table.id) ?? 0,
        onViewOrder: () {
          onTableSelected?.call();
        },
        ref: ref,
      );
    }
  }

  void _onTableLongPress(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    HapticFeedback.mediumImpact();
    _showTableOptionsSheet(context, ref, table);
  }

  void _showOpenTableDialog(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Use dialog for desktop/tablet, bottom sheet for mobile
    if (isDesktop || isTablet) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: isDesktop ? 450 : 400,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: _QuickOpenTableSheet(
              table: table,
              isDialog: true,
              onConfirm: _createOnConfirmCallback(context, ref, table),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _QuickOpenTableSheet(
          table: table,
          onConfirm: _createOnConfirmCallback(context, ref, table),
        ),
      );
    }
  }

  StartSessionCallback _createOnConfirmCallback(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    return ({
      required int guestCount,
      String? guestName,
      String? guestPhone,
      String? notes,
    }) async {
      Navigator.of(context).pop();

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Starting table session...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await ref
          .read(tablesProvider.notifier)
          .openTable(
            table.id,
            guestCount: guestCount,
            guestName: guestName,
            guestPhone: guestPhone,
            notes: notes,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          Toast.success(context, 'Table ${table.name} opened');
          onTableSelected?.call();
        } else {
          Toast.error(context, 'Failed to open table');
        }
      }
    };
  }

  void _showTableOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TableOptionsSheet(
        table: table,
        onAction: (action) {
          Navigator.of(context).pop();
          _handleTableAction(context, ref, table, action);
        },
      ),
    );
  }

  void _handleTableAction(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    String action,
  ) {
    switch (action) {
      case 'addItems':
        onTableSelected?.call();
        break;
      case 'move':
        Toast.info(context, 'Move table - Coming soon');
        break;
      case 'merge':
        Toast.info(context, 'Merge tables - Coming soon');
        break;
      case 'split':
        Toast.info(context, 'Split table - Coming soon');
        break;
      case 'transfer':
        Toast.info(context, 'Transfer table - Coming soon');
        break;
      case 'close':
        ref.read(tablesProvider.notifier).closeTable(table.id);
        Toast.success(context, 'Table ${table.name} closed');
        break;
    }
  }
}

class _OpenTableDialog extends StatefulWidget {
  final RestaurantTable table;
  final ValueChanged<int> onConfirm;

  const _OpenTableDialog({required this.table, required this.onConfirm});

  @override
  State<_OpenTableDialog> createState() => _OpenTableDialogState();
}

class _OpenTableDialogState extends State<_OpenTableDialog> {
  int _guestCount = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Open Table ${widget.table.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select number of guests:'),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _guestCount > 1
                    ? () => setState(() => _guestCount--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  '$_guestCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _guestCount < widget.table.capacity
                    ? () => setState(() => _guestCount++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Capacity: ${widget.table.capacity}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_guestCount),
          child: const Text('Open Table'),
        ),
      ],
    );
  }
}

class _TableOptionsSheet extends StatelessWidget {
  final RestaurantTable table;
  final ValueChanged<String> onAction;

  const _TableOptionsSheet({required this.table, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Table ${table.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Status: ${table.status.displayName}',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          if (table.isOccupied) ...[
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move Table'),
              onTap: () => onAction('move'),
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Merge Tables'),
              onTap: () => onAction('merge'),
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Split Table'),
              onTap: () => onAction('split'),
            ),
            ListTile(
              leading: const Icon(Icons.transfer_within_a_station),
              title: const Text('Transfer Table'),
              onTap: () => onAction('transfer'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.error),
              title: const Text(
                'Close Table',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => onAction('close'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// Floor dropdown selector for captains with multiple floors
class _FloorDropdown extends StatelessWidget {
  final List<Floor> floors;
  final int? selectedFloorId;
  final ValueChanged<int?> onChanged;

  const _FloorDropdown({
    required this.floors,
    required this.selectedFloorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedFloor = selectedFloorId != null
        ? floors.firstWhere(
            (f) => f.id == selectedFloorId,
            orElse: () => floors.first,
          )
        : floors.first;

    return PopupMenuButton<int>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              selectedFloor.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => floors.map((floor) {
        final isSelected = floor.id == (selectedFloorId ?? floors.first.id);
        return PopupMenuItem<int>(
          value: floor.id,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                floor.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Compact button for mobile header
class _CompactButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CompactButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Status indicator dot with count - Clickable for filtering
class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatusDot({
    required this.color,
    required this.label,
    required this.count,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Callback for starting table session with all optional fields
typedef StartSessionCallback =
    Future<void> Function({
      required int guestCount,
      String? guestName,
      String? guestPhone,
      String? notes,
    });

// Quick open table sheet for Captain - responsive for all screen sizes
class _QuickOpenTableSheet extends StatefulWidget {
  final RestaurantTable table;
  final StartSessionCallback onConfirm;
  final bool isDialog;

  const _QuickOpenTableSheet({
    required this.table,
    required this.onConfirm,
    this.isDialog = false,
  });

  @override
  State<_QuickOpenTableSheet> createState() => _QuickOpenTableSheetState();
}

class _QuickOpenTableSheetState extends State<_QuickOpenTableSheet> {
  int _guestCount = 2;
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showOptionalFields = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    // For dialog mode, use different decoration
    if (widget.isDialog) {
      return SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      );
    }

    // Bottom sheet mode
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(child: content),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar (only for bottom sheet)
        if (!widget.isDialog) ...[
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Close button for dialog
        if (widget.isDialog)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        // Table name
        Text(
          'Open Table ${widget.table.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Capacity: ${widget.table.capacity} guests',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        // Guest count selector - Large buttons for easy tap
        const Text(
          'Number of Guests',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GuestCountButton(
              icon: Icons.remove,
              onTap: _guestCount > 1
                  ? () => setState(() => _guestCount--)
                  : null,
            ),
            Container(
              width: 80,
              alignment: Alignment.center,
              child: Text(
                '$_guestCount',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _GuestCountButton(
              icon: Icons.add,
              onTap: _guestCount < widget.table.capacity
                  ? () => setState(() => _guestCount++)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Quick guest buttons
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 5, 6].map((count) {
            if (count > widget.table.capacity) return const SizedBox.shrink();
            final isSelected = count == _guestCount;
            return GestureDetector(
              onTap: () => setState(() => _guestCount = count),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Optional fields toggle
        GestureDetector(
          onTap: () =>
              setState(() => _showOptionalFields = !_showOptionalFields),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showOptionalFields ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _showOptionalFields
                    ? 'Hide Details'
                    : 'Add Guest Details (Optional)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Optional fields
        if (_showOptionalFields) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _guestNameController,
            decoration: InputDecoration(
              labelText: 'Guest Name',
              hintText: 'e.g., Mr. Sharma',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _guestPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g., 9876543210',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'e.g., Birthday celebration',
              prefixIcon: const Icon(Icons.note_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Start button - Large and prominent
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => widget.onConfirm(
              guestCount: _guestCount,
              guestName: _guestNameController.text.isNotEmpty
                  ? _guestNameController.text
                  : null,
              guestPhone: _guestPhoneController.text.isNotEmpty
                  ? _guestPhoneController.text
                  : null,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'START TABLE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (!widget.isDialog)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }
}

class _GuestCountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GuestCountButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.scaffoldBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: isEnabled ? Colors.white : AppColors.textHint,
        ),
      ),
    );
  }
}
