class ReportFilter {
  final String range; // all, daily, weekly, monthly, custom
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportFilter({
    this.range = "all",
    this.fromDate,
    this.toDate,
  });

  ReportFilter copyWith({
    String? range,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ReportFilter(
      range: range ?? this.range,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
