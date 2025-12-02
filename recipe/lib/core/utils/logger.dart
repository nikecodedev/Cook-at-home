import 'package:flutter/foundation.dart';

/// Logger utility for consistent logging across the app
class Logger {
  static const String _prefix = '🔷 SmartPantry';
  
  /// Log information message
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ℹ️ $tagStr $message');
    }
  }
  
  /// Log debug message
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix 🐛 $tagStr $message');
    }
  }
  
  /// Log warning message
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ⚠️ $tagStr $message');
    }
  }
  
  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ❌ $tagStr $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }
  
  /// Log success message
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ✅ $tagStr $message');
    }
  }
  
  /// Log API request
  static void apiRequest(String method, String endpoint, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      print('$_prefix 🌐 API $method $endpoint');
      if (params != null && params.isNotEmpty) {
        print('Params: $params');
      }
    }
  }
  
  /// Log API response
  static void apiResponse(int statusCode, String endpoint, [dynamic data]) {
    if (kDebugMode) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      print('$_prefix $emoji API Response [$statusCode] $endpoint');
      if (data != null) {
        print('Data: $data');
      }
    }
  }
  
  /// Log navigation event
  static void navigation(String routeName) {
    if (kDebugMode) {
      print('$_prefix 🧭 Navigating to: $routeName');
    }
  }
  
  /// Log authentication event
  static void auth(String event) {
    if (kDebugMode) {
      print('$_prefix 🔐 Auth: $event');
    }
  }
  
  /// Log Firebase event
  static void firebase(String event) {
    if (kDebugMode) {
      print('$_prefix 🔥 Firebase: $event');
    }
  }
}

