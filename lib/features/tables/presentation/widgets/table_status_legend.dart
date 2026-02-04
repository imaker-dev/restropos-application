import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/table_entity.dart';

class TableStatusLegend extends StatelessWidget {
  final bool showCounts;
  final Map<TableStatus, int>? counts;

  const TableStatusLegend({
    super.key,
    this.showCounts = false,
    this.counts,
  });

  int? _getCount(TableStatus status) {
    if (!showCounts || counts == null) return null;
    return counts![status];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _LegendItem(
          color: AppColors.tableBlank,
          label: 'Blank Table',
          count: _getCount(TableStatus.blank),
        ),
        _LegendItem(
          color: AppColors.tableRunning,
          label: 'Running Table',
          count: _getCount(TableStatus.running),
        ),
        _LegendItem(
          color: AppColors.tablePrinted,
          label: 'Printed Table',
          count: _getCount(TableStatus.printed),
        ),
        _LegendItem(
          color: AppColors.tablePaid,
          label: 'Paid Table',
          count: _getCount(TableStatus.paid),
        ),
        _LegendItem(
          color: AppColors.tableRunningKot,
          label: 'Running KOT Table',
          count: _getCount(TableStatus.runningKot),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int? count;

  const _LegendItem({
    required this.color,
    required this.label,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          count != null ? '$label ($count)' : label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
