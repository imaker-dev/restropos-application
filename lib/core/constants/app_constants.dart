class AppConstants {
  AppConstants._();

  static const String appName = 'RestroPOS';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.restropos.com';
  static const String wsUrl = 'wss://ws.restropos.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Cache Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String menuCacheKey = 'menu_cache';
  static const String tablesCacheKey = 'tables_cache';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
