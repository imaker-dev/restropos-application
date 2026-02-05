import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/table_entity.dart';

class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TableCard({
    super.key,
    required this.table,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _statusColor => table.status.color;

  Color get _borderColor {
    if (isSelected) return AppColors.primary;
    if (table.status == TableStatus.available) return AppColors.border;
    return _statusColor;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          },
          borderRadius: AppSpacing.borderRadiusSm,
          child: AnimatedContainer(
            duration: AppConstants.shortAnimation,
            decoration: BoxDecoration(
              color: table.status == TableStatus.available
                  ? AppColors.surface
                  : _statusColor.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: _borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Stack(
              children: [
                // Status indicator dot
                if (table.status != TableStatus.available)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                // Table content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        table.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: table.status == TableStatus.available
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (table.runningTotal != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${table.runningTotal!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Lock indicator
                if (table.status == TableStatus.blocked)
                  const Positioned(
                    bottom: 6,
                    right: 6,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
