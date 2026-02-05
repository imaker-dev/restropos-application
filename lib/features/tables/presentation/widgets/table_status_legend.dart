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
          color: AppColors.tableAvailable,
          label: 'Available',
          count: _getCount(TableStatus.available),
        ),
        _LegendItem(
          color: AppColors.tableOccupied,
          label: 'Occupied',
          count: _getCount(TableStatus.occupied),
        ),
        _LegendItem(
          color: AppColors.tableRunning,
          label: 'Running',
          count: _getCount(TableStatus.running),
        ),
        _LegendItem(
          color: AppColors.tableBilling,
          label: 'Billing',
          count: _getCount(TableStatus.billing),
        ),
        _LegendItem(
          color: AppColors.tableCleaning,
          label: 'Cleaning',
          count: _getCount(TableStatus.cleaning),
        ),
        _LegendItem(
          color: AppColors.tableBlocked,
          label: 'Blocked',
          count: _getCount(TableStatus.blocked),
        ),
        _LegendItem(
          color: AppColors.tableReserved,
          label: 'Reserved',
          count: _getCount(TableStatus.reserved),
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
