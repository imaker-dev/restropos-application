import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/order_item.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;
  final bool showKotInfo;

  const OrderItemTile({
    super.key,
    required this.item,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.showKotInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: item.hasKot
            ? AppColors.success.withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.addons.isNotEmpty)
                  Text(
                    item.addons.map((a) => a.name).join(', '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: onDecrement,
                  )
                else
                  const SizedBox(width: 28),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.canModify)
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: onIncrement,
                  )
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.quantity > 1)
                  Text(
                    '₹${item.unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    this.onTap,
  });

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
