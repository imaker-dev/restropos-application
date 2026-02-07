import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/report_filter_model.dart';
import '../../data/model/report_item_model.dart';
import '../../provider/notifier/riverpod_state_notifier.dart';
import 'report_list_item.dart';

class ReportList extends ConsumerWidget {
  const ReportList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final reports = _getFilteredReports(filter);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final data = reports[index];
        return ReportListItem(data: data);
      },
    );
  }

  /// Main filter logic
  List<ReportItem> _getFilteredReports(ReportFilter filter) {
    final allReports = _mockData();

    switch (filter.range) {
      case "all":
        return allReports;

      case "daily":
        final today = _onlyDate(DateTime.now());
        return allReports.where((r) {
          return _onlyDate(r.date) == today;
        }).toList();

      case "weekly":
        final now = DateTime.now();
        final weekStart =
        _onlyDate(now.subtract(Duration(days: now.weekday - 1)));

        return allReports.where((r) {
          return _onlyDate(r.date).isAfter(
              weekStart.subtract(const Duration(days: 1)));
        }).toList();

      case "monthly":
        final now = DateTime.now();
        return allReports.where((r) {
          return r.date.year == now.year &&
              r.date.month == now.month;
        }).toList();

      case "custom":
        if (filter.fromDate == null || filter.toDate == null) {
          return allReports;
        }

        final from = _onlyDate(filter.fromDate!);
        final to = _onlyDate(filter.toDate!);

        return allReports.where((r) {
          final date = _onlyDate(r.date);
          return (date.isAtSameMomentAs(from) || date.isAfter(from)) &&
              (date.isAtSameMomentAs(to) || date.isBefore(to));
        }).toList();

      default:
        return allReports;
    }
  }

  /// Removes time part
  DateTime _onlyDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Mock local report data
  List<ReportItem> _mockData() {
    final now = DateTime.now();

    return [
      ReportItem(
        id: "1",
        title: "Sales Summary",
        date: now,
        orders: 42,
        amount: 6240,
        rangeKey: "daily",
      ),
      ReportItem(
        id: "2",
        title: "Payment Collection Report",
        date: now.subtract(const Duration(days: 2)),
        orders: 210,
        amount: 31200,
        rangeKey: "weekly",
      ),
      ReportItem(
        id: "3",
        title: "Top Selling Items",
        date: now.subtract(const Duration(days: 10)),
        orders: 820,
        amount: 118500,
        rangeKey: "monthly",
      ),
      ReportItem(
        id: "4",
        title: "Order Cancellation Report",
        date: now.subtract(const Duration(days: 1)),
        orders: 8,
        amount: 900,
        rangeKey: "daily",
      ),
      ReportItem(
        id: "5",
        title: "Tax Collection Report",
        date: now.subtract(const Duration(days: 5)),
        orders: 198,
        amount: 28700,
        rangeKey: "weekly",
      ),
    ];
  }
}
