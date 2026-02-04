import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';
import '../providers/order_provider.dart';
import 'order_item_tile.dart';

class OrderSummaryPanel extends ConsumerWidget {
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndPrint;
  final VoidCallback? onKot;
  final VoidCallback? onKotPrint;

  const OrderSummaryPanel({
    super.key,
    this.onSave,
    this.onSaveAndPrint,
    this.onKot,
    this.onKotPrint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider);

    if (order == null) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Header
          _buildHeader(order, ref),
          const Divider(height: 1),
          // Order type tabs
          _buildOrderTypeTabs(order),
          const Divider(height: 1),
          // Table info bar
          _buildTableInfoBar(order),
          // Column headers
          _buildColumnHeaders(),
          const Divider(height: 1),
          // Items list grouped by KOT
          Expanded(
            child: order.items.isEmpty
                ? _buildNoItemsState()
                : _buildItemsList(ref, order),
          ),
          const Divider(height: 1),
          // Payment options
          _buildPaymentOptions(order),
          // Action buttons
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppColors.textHint),
            SizedBox(height: AppSpacing.md),
            Text(
              'No order available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Please Select Item from Left Menu Item\nand create new order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoItemsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: AppColors.textHint),
          SizedBox(height: AppSpacing.sm),
          Text(
            'No items in order',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Order order, WidgetRef ref) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Row(
          children: [
            const Text(
              'Order',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '#${order.id.substring(0, 6).toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            // Show customer name if set
            if (order.customerName != null &&
                order.customerName!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      order.customerName!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            // Customer icon - Add customer
            IconButton(
              icon: Icon(
                order.customerName != null
                    ? Icons.person
                    : Icons.person_add_outlined,
                size: 18,
                color: order.customerName != null ? AppColors.success : null,
              ),
              onPressed: () => _showCustomerDialog(context, ref, order),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: order.customerName != null
                  ? 'Edit Customer'
                  : 'Add Customer',
            ),
            // Note icon - Add note
            IconButton(
              icon: Icon(
                order.notes != null ? Icons.note : Icons.note_add_outlined,
                size: 18,
                color: order.notes != null ? AppColors.info : null,
              ),
              onPressed: () => _showNotesDialog(context, ref, order),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: order.notes != null ? 'Edit Note' : 'Add Note',
            ),
            // Refresh icon
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                // Trigger rebuild
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, WidgetRef ref, Order order) {
    final nameController = TextEditingController(
      text: order.customerName ?? '',
    );
    final phoneController = TextEditingController(
      text: order.customerPhone ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, WidgetRef ref, Order order) {
    final notesController = TextEditingController(text: order.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Enter order notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(currentOrderProvider.notifier)
                  .updateNotes(
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeTabs(Order order) {
    return Container(
      height: 40,
      child: Row(
        children: [
          _OrderTypeTab(
            label: 'Dine In',
            isSelected: order.type == OrderType.dineIn,
          ),
          _OrderTypeTab(
            label: 'Delivery',
            isSelected: order.type == OrderType.delivery,
          ),
          _OrderTypeTab(
            label: 'Pick Up',
            isSelected: order.type == OrderType.pickUp,
          ),
          _OrderTypeTab(label: 'KOT', isSelected: false),
        ],
      ),
    );
  }

  Widget _buildTableInfoBar(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      color: AppColors.scaffoldBackground,
      child: Row(
        children: [
          // Table name badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              order.tableName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Guest count
          _InfoChip(
            icon: Icons.people_outline,
            label: '${order.guestCount}',
            tooltip: 'Guests',
          ),
          const SizedBox(width: 4),
          // Timer
          _InfoChip(
            icon: Icons.timer_outlined,
            label: _getElapsedTime(order.createdAt),
            tooltip: 'Time elapsed',
          ),
          const Spacer(),
          // Order type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              order.type == OrderType.dineIn ? 'Dine In' : order.type.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getElapsedTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.scaffoldBackground,
      child: const Row(
        children: [
          SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Text(
              'ITEMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'QTY.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'PRICE',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(WidgetRef ref, Order order) {
    // Group items by KOT
    final pendingItems = order.pendingItems;
    final kotItems = order.kotItems;

    return ListView(
      children: [
        // KOT items grouped by KOT ID
        if (kotItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            color: AppColors.success.withValues(alpha: 0.1),
            child: Text(
              'KOT - ${kotItems.length} Items',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          ...kotItems.map((item) => OrderItemTile(item: item)),
        ],
        // Pending items
        if (pendingItems.isNotEmpty) ...[
          if (kotItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: const Text(
                'Pending Items',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ...pendingItems.map(
            (item) => OrderItemTile(
              item: item,
              onIncrement: () => ref
                  .read(currentOrderProvider.notifier)
                  .updateItemQuantity(item.id, item.quantity + 1),
              onDecrement: () => ref
                  .read(currentOrderProvider.notifier)
                  .updateItemQuantity(item.id, item.quantity - 1),
              onRemove: () =>
                  ref.read(currentOrderProvider.notifier).removeItem(item.id),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOptions(Order order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // Total display - Full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  '₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Payment mode chips - Scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _PaymentModeChip(label: 'Cash', isSelected: true),
                _PaymentModeChip(label: 'Card', isSelected: false),
                _PaymentModeChip(label: 'UPI', isSelected: false),
                _PaymentModeChip(label: 'Due', isSelected: false),
                _PaymentModeChip(label: 'Split', isSelected: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // First row - Save actions
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  text: 'Save',
                  color: AppColors.info,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ActionBtn(
                  text: 'Print',
                  color: AppColors.info,
                  onPressed: onSaveAndPrint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Second row - KOT actions
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  text: 'KOT',
                  color: order.hasPendingItems
                      ? AppColors.success
                      : AppColors.textHint,
                  onPressed: order.hasPendingItems ? onKot : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  text: 'KOT + Print',
                  color: order.hasPendingItems
                      ? AppColors.secondary
                      : AppColors.textHint,
                  onPressed: order.hasPendingItems ? onKotPrint : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _OrderTypeTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionBtn({required this.text, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PaymentModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _PaymentModeChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 14,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
