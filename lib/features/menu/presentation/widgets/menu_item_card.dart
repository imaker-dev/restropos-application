import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants.dart';
import '../../data/models/menu_models.dart';

class MenuItemCard extends StatelessWidget {
  final ApiMenuItem item;
  final VoidCallback? onTap;
  final bool showPrice;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showPrice = true,
  });

  Color get _typeIndicatorColor {
    switch (item.type) {
      case MenuItemType.veg:
        return AppColors.success;
      case MenuItemType.nonVeg:
        return AppColors.error;
      case MenuItemType.egg:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusSm,
        child: InkWell(
          onTap: item.isAvailable
              ? () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                }
              : null,
          borderRadius: AppSpacing.borderRadiusSm,
          child: Container(
            padding: AppSpacing.paddingSm,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg/Non-veg indicator
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 2, right: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _typeIndicatorColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _typeIndicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Item name
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: item.isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (showPrice) ...[
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.isAvailable
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      // Tags row
                      if (item.hasVariants)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Variants',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      if (item.hasAddons)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Add-ons',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (!item.isAvailable)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Not Available',
                      style: TextStyle(fontSize: 10, color: AppColors.error),
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
