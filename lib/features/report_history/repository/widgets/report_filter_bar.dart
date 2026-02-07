import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/model/report_filter_model.dart';
import '../../provider/notifier/riverpod_state_notifier.dart';

class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(context, ref, "All", "all"),
                // const SizedBox(width: 8),
                _chip(context, ref, "Day", "daily"),
                // const SizedBox(width: 8),
                _chip(context, ref, "Week", "weekly"),
                // const SizedBox(width: 8),
                _chip(context, ref, "Month", "monthly"),
                // const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _pickDateRange(context, ref),
                  icon: const Icon(Icons.date_range),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          /// Date range display
          if (filter.range == "custom")
            _buildDateRangeDisplay(filter),
        ],
      ),
    );
  }
  Widget _buildDateRangeDisplay(ReportFilter filter) {
    String format(DateTime? d) {
      if (d == null) return "--";
      return "${d.day.toString().padLeft(2, '0')} "
          "${_monthName(d.month)} "
          "${d.year}";
    }

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Start Date",
                style: AppTextStyles.textSecondary12Medium,
              ),
              const SizedBox(height: 4),
              Text(
                format(filter.fromDate),
                style: AppTextStyles.primary14SemiBold,
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "End Date",
                style: AppTextStyles.textSecondary12Medium,
              ),
              const SizedBox(height: 4),
              Text(
                format(filter.toDate),
                style: AppTextStyles.primary14SemiBold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return names[month - 1];
  }
  Future<void> _pickDateRange(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    if (range != null) {
      ref.read(reportFilterProvider.notifier).setCustomRange(
        range.start,
        range.end,
      );
    }
  }

  Widget _chip(
      BuildContext context,
      WidgetRef ref,
      String label,
      String key,
      ) {
    final filter = ref.watch(reportFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: filter.range == key,
        onSelected: (_) {
          final notifier = ref.read(reportFilterProvider.notifier);

          switch (key) {
            case "all":
              notifier.setAll();
              break;
            case "daily":
              notifier.setDaily();
              break;
            case "weekly":
              notifier.setWeekly();
              break;
            case "monthly":
              notifier.setMonthly();
              break;
          }
        },
      ),
    );
  }
}

