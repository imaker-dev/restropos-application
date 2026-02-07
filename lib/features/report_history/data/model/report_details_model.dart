import 'package:flutter/material.dart';

class ReportDetails {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? generatedAt;
  final String rangeKey;
  final ReportSummary summary;
  final List<ReportItem> items;
  final List<ReportChart> charts;
  final Map<String, dynamic>? metadata;

  const ReportDetails({
    required this.id,
    required this.title,
    required this.date,
    this.generatedAt,
    required this.rangeKey,
    required this.summary,
    required this.items,
    required this.charts,
    this.metadata,
  });

  /// Create a copy with updated values
  ReportDetails copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? generatedAt,
    String? rangeKey,
    ReportSummary? summary,
    List<ReportItem>? items,
    List<ReportChart>? charts,
    Map<String, dynamic>? metadata,
  }) {
    return ReportDetails(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      generatedAt: generatedAt ?? this.generatedAt,
      rangeKey: rangeKey ?? this.rangeKey,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      charts: charts ?? this.charts,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'generatedAt': generatedAt?.toIso8601String(),
      'rangeKey': rangeKey,
      'summary': summary.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'charts': charts.map((chart) => chart.toMap()).toList(),
      'metadata': metadata,
    };
  }

  /// Create from map
  factory ReportDetails.fromMap(Map<String, dynamic> map) {
    return ReportDetails(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      generatedAt: map['generatedAt'] != null ? DateTime.parse(map['generatedAt']) : null,
      rangeKey: map['rangeKey'] ?? '',
      summary: ReportSummary.fromMap(map['summary'] ?? {}),
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => ReportItem.fromMap(item))
          .toList() ?? [],
      charts: (map['charts'] as List<dynamic>?)
          ?.map((chart) => ReportChart.fromMap(chart))
          .toList() ?? [],
      metadata: map['metadata'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportDetails &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.generatedAt == generatedAt &&
        other.rangeKey == rangeKey &&
        other.summary == summary &&
        other.items == items &&
        other.charts == charts &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        date.hashCode ^
        generatedAt.hashCode ^
        rangeKey.hashCode ^
        summary.hashCode ^
        items.hashCode ^
        charts.hashCode ^
        metadata.hashCode;
  }

  @override
  String toString() {
    return 'ReportDetails(id: $id, title: $title, date: $date, rangeKey: $rangeKey)';
  }
}

class ReportSummary {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int totalItems;
  final double taxAmount;
  final double discountAmount;
  final int cancelledOrders;
  final Map<String, int> paymentMethods;

  const ReportSummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalItems,
    required this.taxAmount,
    required this.discountAmount,
    required this.cancelledOrders,
    required this.paymentMethods,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'totalItems': totalItems,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'cancelledOrders': cancelledOrders,
      'paymentMethods': paymentMethods,
    };
  }

  factory ReportSummary.fromMap(Map<String, dynamic> map) {
    return ReportSummary(
      totalOrders: map['totalOrders']?.toInt() ?? 0,
      totalRevenue: map['totalRevenue']?.toDouble() ?? 0.0,
      averageOrderValue: map['averageOrderValue']?.toDouble() ?? 0.0,
      totalItems: map['totalItems']?.toInt() ?? 0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      discountAmount: map['discountAmount']?.toDouble() ?? 0.0,
      cancelledOrders: map['cancelledOrders']?.toInt() ?? 0,
      paymentMethods: Map<String, int>.from(map['paymentMethods'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportSummary &&
        other.totalOrders == totalOrders &&
        other.totalRevenue == totalRevenue &&
        other.averageOrderValue == averageOrderValue &&
        other.totalItems == totalItems &&
        other.taxAmount == taxAmount &&
        other.discountAmount == discountAmount &&
        other.cancelledOrders == cancelledOrders &&
        other.paymentMethods == paymentMethods;
  }

  @override
  int get hashCode {
    return totalOrders.hashCode ^
        totalRevenue.hashCode ^
        averageOrderValue.hashCode ^
        totalItems.hashCode ^
        taxAmount.hashCode ^
        discountAmount.hashCode ^
        cancelledOrders.hashCode ^
        paymentMethods.hashCode;
  }
}

class ReportItem {
  final String name;
  final int quantity;
  final double revenue;
  final double percentage;

  const ReportItem({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'revenue': revenue,
      'percentage': percentage,
    };
  }

  factory ReportItem.fromMap(Map<String, dynamic> map) {
    return ReportItem(
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      revenue: map['revenue']?.toDouble() ?? 0.0,
      percentage: map['percentage']?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportItem &&
        other.name == name &&
        other.quantity == quantity &&
        other.revenue == revenue &&
        other.percentage == percentage;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        quantity.hashCode ^
        revenue.hashCode ^
        percentage.hashCode;
  }
}

class ReportChart {
  final String type; // 'pie', 'bar', 'line'
  final String title;
  final List<ChartData> data;
  final Map<String, dynamic>? config;

  const ReportChart({
    required this.type,
    required this.title,
    required this.data,
    this.config,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'data': data.map((item) => item.toMap()).toList(),
      'config': config,
    };
  }

  factory ReportChart.fromMap(Map<String, dynamic> map) {
    return ReportChart(
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      data: (map['data'] as List<dynamic>?)
          ?.map((item) => ChartData.fromMap(item))
          .toList() ?? [],
      config: map['config'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportChart &&
        other.type == type &&
        other.title == title &&
        other.data == data &&
        other.config == config;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        title.hashCode ^
        data.hashCode ^
        config.hashCode;
  }
}

class ChartData {
  final String label;
  final double value;
  final String? category;
  final Color? color;

  const ChartData({
    required this.label,
    required this.value,
    this.category,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'category': category,
      'color': color?.value,
    };
  }

  factory ChartData.fromMap(Map<String, dynamic> map) {
    return ChartData(
      label: map['label'] ?? '',
      value: map['value']?.toDouble() ?? 0.0,
      category: map['category'],
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartData &&
        other.label == label &&
        other.value == value &&
        other.category == category &&
        other.color == color;
  }

  @override
  int get hashCode {
    return label.hashCode ^
        value.hashCode ^
        category.hashCode ^
        color.hashCode;
  }
}
