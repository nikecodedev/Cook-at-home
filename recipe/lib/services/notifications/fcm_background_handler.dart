import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
/// This file must be imported in main.dart before runApp()
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate if not already initialized
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (kDebugMode) {
      print('Firebase initialized in background handler');
    }
  } catch (e) {
    // Firebase might already be initialized, ignore error
    if (kDebugMode) {
      print('Firebase initialization in background handler (might already be initialized): $e');
    }
  }

  if (kDebugMode) {
    print('=== BACKGROUND MESSAGE HANDLER ===');
    print('Message ID: ${message.messageId}');
    print('Message from: ${message.from}');
    print('Message title: ${message.notification?.title}');
    print('Message body: ${message.notification?.body}');
    print('Message data: ${message.data}');
    print('Sent time: ${message.sentTime}');
    print('===================================');
  }
  
  // Note: Logger might not work in background isolate, so we use print
  // Logger.info('Background message handler: ${message.messageId}', 'FCMBackgroundHandler');
  
  // You can perform background tasks here, such as:
  // - Updating local database
  // - Scheduling local notifications
  // - Logging analytics
  
  // Note: In background, you cannot update UI directly
  // The notification will be shown automatically by the system
  // When user taps it, onMessageOpenedApp or getInitialMessage will be called
}

