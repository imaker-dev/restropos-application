import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/report_filter_model.dart';

final reportFilterProvider =
StateNotifierProvider<ReportFilterNotifier, ReportFilter>((ref) {
  return ReportFilterNotifier();
});

class ReportFilterNotifier extends StateNotifier<ReportFilter> {
  ReportFilterNotifier() : super(const ReportFilter());

  void setAll() {
    state = const ReportFilter(range: "all");
  }

  void setDaily() {
    state = const ReportFilter(range: "daily");
  }

  void setWeekly() {
    state = const ReportFilter(range: "weekly");
  }

  void setMonthly() {
    state = const ReportFilter(range: "monthly");
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = ReportFilter(
      range: "custom",
      fromDate: from,
      toDate: to,
    );
  }
}
