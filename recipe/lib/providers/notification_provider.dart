import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notifications/fcm_service.dart';
import '../services/firestore/firestore_service.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';
import '../core/utils/logger.dart';

/// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) => FCMService());

/// Provider for notification state
final notificationStateProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return NotificationNotifier(fcmService, firestoreService, ref);
});

/// Notification state
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationState({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// In-app notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? type; // 'pantry_expiry', 'recipe_suggestion', etc.

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.type,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      type: type ?? this.type,
    );
  }
}

/// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final FCMService _fcmService;
  final FirestoreService _firestoreService;
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationNotifier(this._fcmService, this._firestoreService, this._ref)
      : super(NotificationState(notifications: [], unreadCount: 0)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize FCM with timeout and error handling
      await _fcmService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger.warning('FCM initialization timeout, continuing without notifications', 'NotificationNotifier');
        },
      ).catchError((e, stackTrace) {
        Logger.error('FCM initialization failed, continuing without notifications', e, stackTrace, 'NotificationNotifier');
        // Don't rethrow - allow app to continue without notifications
        return;
      });

      // Save token to Firestore (wait a bit for user to be logged in)
      _saveTokenWhenUserAvailable();

      // Listen to foreground messages (when app is in foreground)
      _fcmService.onMessage.listen((message) {
        print('Foreground message received: ${message.messageId}');
        _handleMessage(message);
      }).onError((error) {
        Logger.error('Error listening to foreground messages', error, null, 'NotificationNotifier');
      });

      // Listen to messages that opened the app (when app was in background/terminated)
      _fcmService.onMessageOpenedApp.listen((message) {
        print('App opened from notification: ${message.messageId}');
        _handleMessage(message);
      }).onError((error) {
        Logger.error('Error listening to message opened app', error, null, 'NotificationNotifier');
      });

      // Check if app was opened from a notification (when app was terminated)
      try {
        final initialMessage = await _fcmService.getInitialMessage()
            .timeout(const Duration(seconds: 2));
        if (initialMessage != null) {
          print('App opened from terminated state notification: ${initialMessage.messageId}');
          _handleMessage(initialMessage);
        }
      } catch (e) {
        Logger.warning('Error getting initial message', 'NotificationNotifier');
      }

      // Listen for token refresh and update Firestore
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM token refreshed: ${newToken.substring(0, 20)}...');
        final userId = _ref.read(currentUserIdProvider);
        if (userId != null) {
          _firestoreService.updateUserFCMToken(userId, newToken).catchError((e) {
            Logger.error('Failed to update FCM token after refresh', e, null, 'NotificationNotifier');
          });
        }
      }).onError((error) {
        Logger.error('Error listening to token refresh', error, null, 'NotificationNotifier');
      });
    } catch (e, stackTrace) {
      // Handle initialization errors gracefully
      print('FCM initialization error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Save token when user becomes available
  void _saveTokenWhenUserAvailable() {
    // Check immediately
    final userId = _ref.read(currentUserIdProvider);
    if (userId != null && _fcmService.fcmToken != null) {
      _firestoreService.updateUserFCMToken(userId, _fcmService.fcmToken!).catchError((e) {
        print('Failed to save FCM token: $e');
      });
      return;
    }

    // If user not available, listen for auth state changes
    _ref.listen(currentUserIdProvider, (previous, next) {
      if (next != null && _fcmService.fcmToken != null) {
        _firestoreService.updateUserFCMToken(next, _fcmService.fcmToken!).catchError((e) {
          print('Failed to save FCM token: $e');
        });
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    try {
      print('Handling message: ${message.messageId}');
      print('Message title: ${message.notification?.title}');
      print('Message body: ${message.notification?.body}');
      print('Message data: ${message.data}');

      final notification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? message.data['title'] ?? 'Notification',
        body: message.notification?.body ?? message.data['body'] ?? '',
        timestamp: message.sentTime ?? DateTime.now(),
        isRead: false,
        data: message.data,
        type: message.data['type'] ?? message.data['notification_type'],
      );

      // Add to notifications list
      final updatedNotifications = [notification, ...state.notifications];
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      print('Notification added. Total: ${updatedNotifications.length}, Unread: $newUnreadCount');
    } catch (e, stackTrace) {
      print('Error handling message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notif) {
      if (notif.id == notificationId && !notif.isRead) {
        return notif.copyWith(isRead: true);
      }
      return notif;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  /// Mark all as read
  void markAllAsRead() {
    final updatedNotifications = state.notifications
        .map((notif) => notif.copyWith(isRead: true))
        .toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );
  }

  /// Clear all notifications
  void clearAll() {
    state = NotificationState(notifications: [], unreadCount: 0);
  }

  /// Remove notification
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((notif) => notif.id != notificationId)
        .toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }
}

