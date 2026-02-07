class ReportItem {
  final String id;
  final String title;
  final DateTime date;
  final int orders;
  final double amount;
  final String rangeKey; // daily, weekly, monthly

  const ReportItem({
    required this.id,
    required this.title,
    required this.date,
    required this.orders,
    required this.amount,
    required this.rangeKey,
  });
}
