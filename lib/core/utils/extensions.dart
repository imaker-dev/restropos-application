import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<T?> showBottomSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      builder: (_) => child,
    );
  }
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
  
  bool get isValidPhone {
    return RegExp(r'^[0-9]{10}$').hasMatch(this);
  }
}

extension NumExtensions on num {
  String get toCurrency {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(this);
  }
  
  String get toCompactCurrency {
    return NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0).format(this);
  }
  
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
}

extension DateTimeExtensions on DateTime {
  String get toTimeString {
    return DateFormat('HH:mm').format(this);
  }
  
  String get toDateString {
    return DateFormat('dd MMM yyyy').format(this);
  }
  
  String get toDateTimeString {
    return DateFormat('dd MMM yyyy, HH:mm').format(this);
  }
  
  String get toApiFormat {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  }
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  
  List<T> separatedBy(T separator) {
    if (length <= 1) return this;
    return [
      for (int i = 0; i < length; i++) ...[
        this[i],
        if (i < length - 1) separator,
      ],
    ];
  }
}

extension WidgetExtensions on Widget {
  Widget padAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );
  
  Widget padSymmetric({double horizontal = 0, double vertical = 0}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: this,
      );
  
  Widget padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
        child: this,
      );
  
  Widget centered() => Center(child: this);
  
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);
  
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);
}
