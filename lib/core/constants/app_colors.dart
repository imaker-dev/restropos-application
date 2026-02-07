import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFE53935);
  static const Color primaryLight = Color(0xFFFF6F60);
  static const Color primaryDark = Color(0xFFAB000D);

  // Secondary Colors
  static const Color secondary = Color(0xFF424242);
  static const Color secondaryLight = Color(0xFF6D6D6D);
  static const Color secondaryDark = Color(0xFF1B1B1B);

  // Accent Colors
  static const Color accent = Color(0xFFFFC107);
  static const Color accentLight = Color(0xFFFFF350);
  static const Color accentDark = Color(0xFFC79100);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color refunded = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);  // For completed orders
  static const Color cancelled = Color(0xFFEF4444);  // For cancelled orders

  // Table Status Colors
  static const Color tableAvailable = Color(0xFF4CAF50);  // Green - available for seating
  static const Color tableOccupied = Color(0xFF42A5F5);   // Blue - guests seated, order in progress
  static const Color tableRunning = Color(0xFF2196F3);    // Blue - order running with KOTs
  static const Color tableBilling = Color(0xFFFF9800);    // Orange - bill generated, awaiting payment
  static const Color tableCleaning = Color(0xFF9E9E9E);   // Grey - needs cleaning
  static const Color tableBlocked = Color(0xFFEF5350);    // Red - blocked/unavailable
  static const Color tableReserved = Color(0xFF9C27B0);   // Purple - reserved

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Overlay
  static const Color overlay = Color(0x80000000);
}
