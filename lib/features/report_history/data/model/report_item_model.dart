import 'report_history_model.dart';

class ReportItem extends ReportHistory {
  final String? status;
  final String? priority;
  final bool isGenerated;

  const ReportItem({
    required super.id,
    required super.title,
    required super.date,
    required super.orders,
    required super.amount,
    required super.rangeKey,
    super.description,
    super.category,
    this.status,
    this.priority,
    this.isGenerated = false,
  });

  /// Create a ReportItem from ReportHistory
  factory ReportItem.fromReportHistory(ReportHistory report, {
    String? status,
    String? priority,
    bool isGenerated = false,
  }) {
    return ReportItem(
      id: report.id,
      title: report.title,
      date: report.date,
      orders: report.orders,
      amount: report.amount,
      rangeKey: report.rangeKey,
      description: report.description,
      category: report.category,
      status: status,
      priority: priority,
      isGenerated: isGenerated,
    );
  }

  /// Create a copy with updated values
  ReportItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? orders,
    double? amount,
    String? rangeKey,
    String? description,
    String? category,
    String? status,
    String? priority,
    bool? isGenerated,
  }) {
    return ReportItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      orders: orders ?? this.orders,
      amount: amount ?? this.amount,
      rangeKey: rangeKey ?? this.rangeKey,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  /// Convert to map for easy serialization
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'status': status,
      'priority': priority,
      'isGenerated': isGenerated,
    });
    return map;
  }

  /// Create from map
  factory ReportItem.fromMap(Map<String, dynamic> map) {
    return ReportItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      orders: map['orders']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      rangeKey: map['rangeKey'] ?? '',
      description: map['description'],
      category: map['category'],
      status: map['status'],
      priority: map['priority'],
      isGenerated: map['isGenerated'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportItem &&
        super == other &&
        other.status == status &&
        other.priority == priority &&
        other.isGenerated == isGenerated;
  }

  @override
  int get hashCode {
    return super.hashCode ^
        status.hashCode ^
        priority.hashCode ^
        isGenerated.hashCode;
  }

  @override
  String toString() {
    return 'ReportItem(id: $id, title: $title, date: $date, status: $status, priority: $priority)';
  }
}
