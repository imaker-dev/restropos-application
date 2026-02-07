class ReportHistory {
  final String id;
  final String title;
  final DateTime date;
  final int orders;
  final double amount;
  final String rangeKey; // daily, weekly, monthly
  final String? description;
  final String? category;

  const ReportHistory({
    required this.id,
    required this.title,
    required this.date,
    required this.orders,
    required this.amount,
    required this.rangeKey,
    this.description,
    this.category,
  });

  /// Create a copy with updated values
  ReportHistory copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? orders,
    double? amount,
    String? rangeKey,
    String? description,
    String? category,
  }) {
    return ReportHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      orders: orders ?? this.orders,
      amount: amount ?? this.amount,
      rangeKey: rangeKey ?? this.rangeKey,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  /// Convert to map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'orders': orders,
      'amount': amount,
      'rangeKey': rangeKey,
      'description': description,
      'category': category,
    };
  }

  /// Create from map
  factory ReportHistory.fromMap(Map<String, dynamic> map) {
    return ReportHistory(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      orders: map['orders']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      rangeKey: map['rangeKey'] ?? '',
      description: map['description'],
      category: map['category'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportHistory &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.orders == orders &&
        other.amount == amount &&
        other.rangeKey == rangeKey &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        date.hashCode ^
        orders.hashCode ^
        amount.hashCode ^
        rangeKey.hashCode ^
        description.hashCode ^
        category.hashCode;
  }

  @override
  String toString() {
    return 'ReportHistory(id: $id, title: $title, date: $date, orders: $orders, amount: $amount, rangeKey: $rangeKey)';
  }
}
