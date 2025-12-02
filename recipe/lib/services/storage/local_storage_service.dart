import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local Storage Service using SharedPreferences
/// For storing non-sensitive data locally
class LocalStorageService {
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  /// This should be called in main() with a timeout wrapper
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('LocalStorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ========== String Operations ==========

  /// Save string value
  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }

  /// Get string value
  static String? getString(String key) {
    return instance.getString(key);
  }

  // ========== Int Operations ==========

  /// Save int value
  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }

  /// Get int value
  static int? getInt(String key) {
    return instance.getInt(key);
  }

  // ========== Double Operations ==========

  /// Save double value
  static Future<bool> setDouble(String key, double value) async {
    return await instance.setDouble(key, value);
  }

  /// Get double value
  static double? getDouble(String key) {
    return instance.getDouble(key);
  }

  // ========== Bool Operations ==========

  /// Save bool value
  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }

  /// Get bool value
  static bool? getBool(String key) {
    return instance.getBool(key);
  }

  // ========== List Operations ==========

  /// Save list of strings
  static Future<bool> setStringList(String key, List<String> value) async {
    return await instance.setStringList(key, value);
  }

  /// Get list of strings
  static List<String>? getStringList(String key) {
    return instance.getStringList(key);
  }

  // ========== Object Operations (JSON) ==========

  /// Save object as JSON
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    return await setString(key, jsonString);
  }

  /// Get object from JSON
  static Map<String, dynamic>? getObject(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // ignore: avoid_print
      print('Error decoding JSON for key $key: $e');
      return null;
    }
  }

  // ========== Remove & Clear Operations ==========

  /// Remove specific key
  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }

  /// Clear all data
  static Future<bool> clear() async {
    return await instance.clear();
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return instance.containsKey(key);
  }

  /// Get all keys
  static Set<String> getAllKeys() {
    return instance.getKeys();
  }

  // ========== Common App Settings Keys ==========

  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyExpiryAlertsEnabled = 'expiry_alerts_enabled';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // ========== Helper Methods ==========

  /// Check if it's first launch
  static bool isFirstLaunch() {
    final isFirst = getBool(keyIsFirstLaunch);
    if (isFirst == null) {
      setFirstLaunch(false);
      return true;
    }
    return isFirst;
  }

  /// Set first launch flag
  static Future<bool> setFirstLaunch(bool value) {
    return setBool(keyIsFirstLaunch, value);
  }

  /// Save user data
  static Future<void> saveUserData({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    await setString(keyUserId, userId);
    await setString(keyUserEmail, email);
    if (displayName != null) {
      await setString(keyUserName, displayName);
    }
  }

  /// Clear user data (on logout)
  static Future<void> clearUserData() async {
    await remove(keyUserId);
    await remove(keyUserEmail);
    await remove(keyUserName);
  }

  /// Get saved user ID
  static String? getUserId() {
    return getString(keyUserId);
  }

  /// Get saved user email
  static String? getUserEmail() {
    return getString(keyUserEmail);
  }

  /// Get saved user name
  static String? getUserName() {
    return getString(keyUserName);
  }
}

