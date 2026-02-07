import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/order_item.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final bool showKotInfo;

  const OrderItemTile({
    super.key,
    required this.item,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.onTap,
    this.onCancel,
    this.showKotInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: item.status == OrderItemStatus.cancelled
              ? AppColors.error.withValues(alpha: 0.05)
              : item.hasKot
              ? AppColors.success.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Remove button (only for pending items) or lock indicator for KOT items
                if (item.canModify)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  )
                else if (item.status == OrderItemStatus.cancelled)
                  Tooltip(
                    message: 'Item cancelled',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.cancel,
                        size: 14,
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else if (onCancel != null)
                  GestureDetector(
                    onTap: onCancel,
                    child: Tooltip(
                      message: 'Cancel item',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: AppColors.error.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                else
                  Tooltip(
                    message: 'Item sent to kitchen (locked)',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: AppColors.warning.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                // Item details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.variantName != null
                            ? '${item.name} (${item.variantName})'
                            : item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: item.status == OrderItemStatus.cancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.error,
                          color: item.status == OrderItemStatus.cancelled
                              ? AppColors.textSecondary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.addons.isNotEmpty)
                        Text(
                          item.addons.map((a) => a.name).join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            decoration: item.status == OrderItemStatus.cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Quantity controls
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.canModify)
                        _QuantityButton(icon: Icons.remove, onTap: onDecrement)
                      else
                        const SizedBox(width: 28),
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: item.status == OrderItemStatus.cancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.error,
                            color: item.status == OrderItemStatus.cancelled
                                ? AppColors.textSecondary
                                : null,
                          ),
                        ),
                      ),
                      if (item.canModify)
                        _QuantityButton(icon: Icons.add, onTap: onIncrement)
                      else
                        const SizedBox(width: 28),
                    ],
                  ),
                ),
                // Price
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.itemTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: item.status == OrderItemStatus.cancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.error,
                          color: item.status == OrderItemStatus.cancelled
                              ? AppColors.textSecondary
                              : null,
                        ),
                      ),
                      if (item.quantity > 1)
                        Text(
                          '₹${item.unitPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            decoration: item.status == OrderItemStatus.cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Special instructions
            if (item.specialInstructions != null &&
                item.specialInstructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 12, color: AppColors.info),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.specialInstructions!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.info,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}
