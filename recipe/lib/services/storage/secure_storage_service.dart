import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service using FlutterSecureStorage
/// For storing sensitive data like tokens and credentials
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ========== Read Operations ==========

  /// Read value
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // ignore: avoid_print
      print('Error reading from secure storage: $e');
      return null;
    }
  }

  /// Read all values
  static Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      // ignore: avoid_print
      print('Error reading all from secure storage: $e');
      return {};
    }
  }

  // ========== Write Operations ==========

  /// Write value
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // ignore: avoid_print
      print('Error writing to secure storage: $e');
      rethrow;
    }
  }

  // ========== Delete Operations ==========

  /// Delete specific key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting from secure storage: $e');
      rethrow;
    }
  }

  /// Delete all keys
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting all from secure storage: $e');
      rethrow;
    }
  }

  // ========== Check Operations ==========

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    try {
      final value = await read(key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  // ========== Common Storage Keys ==========

  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyApiKey = 'api_key';
  static const String keyUserPassword = 'user_password'; // For biometric re-auth
  static const String keyBiometricEnabled = 'biometric_enabled';

  // ========== Helper Methods ==========

  /// Save authentication tokens
  static Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await write(keyAuthToken, accessToken);
    if (refreshToken != null) {
      await write(keyRefreshToken, refreshToken);
    }
  }

  /// Get access token
  static Future<String?> getAuthToken() async {
    return await read(keyAuthToken);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await read(keyRefreshToken);
  }

  /// Clear authentication tokens
  static Future<void> clearAuthTokens() async {
    await delete(keyAuthToken);
    await delete(keyRefreshToken);
  }

  /// Check if user is authenticated (has token)
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Save API key
  static Future<void> saveApiKey(String apiKey) async {
    await write(keyApiKey, apiKey);
  }

  /// Get API key
  static Future<String?> getApiKey() async {
    return await read(keyApiKey);
  }

  /// Enable biometric authentication
  static Future<void> enableBiometric(String password) async {
    await write(keyUserPassword, password);
    await write(keyBiometricEnabled, 'true');
  }

  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    await delete(keyUserPassword);
    await delete(keyBiometricEnabled);
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await read(keyBiometricEnabled);
    return enabled == 'true';
  }

  /// Get stored password (for biometric re-auth)
  static Future<String?> getStoredPassword() async {
    return await read(keyUserPassword);
  }
}

