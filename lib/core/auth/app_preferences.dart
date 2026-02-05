import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String _keySessionToken = 'session_token';
  static const String _keyUserId = 'user_id';

  /// Save session token
  static Future<void> setSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionToken, token);
  }

  /// Get session token
  static Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionToken);
  }

  /// Check if token exists
  static Future<bool> hasSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keySessionToken);
  }

  /// Clear session token (logout)
  static Future<void> clearSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionToken);
  }

  /// Save user ID
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Check if user ID exists
  static Future<bool> hasUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserId);
  }

  /// Clear user ID
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  /// Clear all session data (token and user ID)
  static Future<void> clearAllSessionData() async {
    await clearSessionToken();
    await clearUserId();
  }
}
