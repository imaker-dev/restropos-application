import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int tableCount;
  final VoidCallback? onTap;
  final bool isExpanded;

  const SectionHeader({
    super.key,
    required this.title,
    this.tableCount = 0,
    this.onTap,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (tableCount > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusXs,
              ),
              child: Text(
                '$tableCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onTap != null)
            IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}
