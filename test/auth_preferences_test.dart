import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/auth/app_preferences.dart';

void main() {
  group('AppPreferences Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Should save and retrieve session token', () async {
      const testToken = 'test_token_123';
      
      // Save token
      await AppPreferences.setSessionToken(testToken);
      
      // Retrieve token
      final retrievedToken = await AppPreferences.getSessionToken();
      
      expect(retrievedToken, equals(testToken));
    });

    test('Should check if token exists', () async {
      // Initially no token
      expect(await AppPreferences.hasSessionToken(), isFalse);
      
      // Save token
      await AppPreferences.setSessionToken('test_token');
      
      // Now token should exist
      expect(await AppPreferences.hasSessionToken(), isTrue);
    });

    test('Should save and retrieve user ID', () async {
      const testUserId = 'user_456';
      
      // Save user ID
      await AppPreferences.setUserId(testUserId);
      
      // Retrieve user ID
      final retrievedUserId = await AppPreferences.getUserId();
      
      expect(retrievedUserId, equals(testUserId));
    });

    test('Should clear session token', () async {
      // Save token
      await AppPreferences.setSessionToken('test_token');
      expect(await AppPreferences.hasSessionToken(), isTrue);
      
      // Clear token
      await AppPreferences.clearSessionToken();
      expect(await AppPreferences.hasSessionToken(), isFalse);
      expect(await AppPreferences.getSessionToken(), isNull);
    });

    test('Should clear all session data', () async {
      // Save token and user ID
      await AppPreferences.setSessionToken('test_token');
      await AppPreferences.setUserId('user_123');
      
      expect(await AppPreferences.hasSessionToken(), isTrue);
      expect(await AppPreferences.hasUserId(), isTrue);
      
      // Clear all data
      await AppPreferences.clearAllSessionData();
      
      expect(await AppPreferences.hasSessionToken(), isFalse);
      expect(await AppPreferences.hasUserId(), isFalse);
    });
  });
}
