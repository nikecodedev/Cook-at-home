import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/storage/local_storage_service.dart';
import 'services/notifications/fcm_background_handler.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'services/firestore/firestore_service.dart';
import 'repositories/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/config/firebase_config.dart';
import 'core/localization/app_localizations.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with aggressive timeout and error handling
  // Use shorter timeout to ensure app starts quickly - NEVER wait more than 5 seconds
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        Logger.error('Firebase initialization timeout after 5s - continuing anyway', null, null, 'Main');
        throw TimeoutException('Firebase initialization timed out after 5 seconds');
      },
    );
    Logger.firebase('Firebase initialized successfully');
  } catch (e) {
    Logger.error('Firebase initialization failed - continuing anyway', e, null, 'Main');
    // ALWAYS continue - Firebase might work partially or user can retry
    // The app MUST proceed to login screen even if Firebase fails
  }

  // Initialize Local Storage with aggressive timeout and error handling
  // Use shorter timeout - NEVER wait more than 3 seconds
  try {
    await LocalStorageService.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        Logger.error('Local storage initialization timeout after 3s - continuing anyway', null, null, 'Main');
        throw TimeoutException('Local storage initialization timed out after 3 seconds');
      },
    );
    Logger.info('Local storage initialized successfully', 'Main');
  } catch (e) {
    Logger.error('Local storage initialization failed - continuing anyway', e, null, 'Main');
    // ALWAYS continue - app can work without local storage
    // The app MUST proceed to login screen even if storage fails
  }

  // Initialize FCM background handler (non-blocking)
  try {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  Logger.info('FCM background handler registered', 'Main');
  } catch (e) {
    Logger.error('FCM background handler registration failed', e, null, 'Main');
    // Continue anyway - notifications are not critical
  }

  // Run app with Riverpod - always proceed even if initialization failed
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM when app starts
    // The NotificationNotifier will initialize itself when created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wrap in try-catch and timeout to prevent hanging
      Future.microtask(() async {
      try {
          // Handle email verification link (for web) with timeout
          await _handleEmailVerificationLink()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            Logger.warning('Email verification link handling timed out', 'Main');
          });
        } catch (e) {
          Logger.error('Error handling email verification link', e, null, 'Main');
        }

        try {
        // Access the notifier to trigger initialization
        // The notifier initializes FCM in its constructor
        final notifier = ref.read(notificationStateProvider.notifier);
          Logger.info('Notification notifier initialized', 'Main');
        } catch (e) {
          Logger.error('Error initializing notification notifier', e, null, 'Main');
        }
      });
    });
  }

  /// Handle email verification link when app opens from email (web only)
  Future<void> _handleEmailVerificationLink() async {
    if (!kIsWeb) return;
    
    try {
      // Check if URL contains email verification parameters (web only)
      final uri = Uri.base;
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      
      if (mode == 'verifyEmail' && oobCode != null) {
        Logger.info('Email verification link detected in main.dart', 'Main');
        
        try {
          // Apply the action code directly to verify the email with timeout
          final auth = FirebaseConfig.auth;
          
          // Check if user is logged in
          final currentUser = auth.currentUser;
          if (currentUser == null) {
            Logger.warning('No user logged in when processing verification link', 'Main');
            // User might need to log in first, but the link should still work
            // Firebase will verify when they log in
            return;
          }
          
          // Apply the verification code using FirebaseAuth with timeout
          await auth.applyActionCode(oobCode).timeout(const Duration(seconds: 5));
          Logger.success('Email verified via action code', 'Main');
          
          // Reload user to get updated verification status with timeout
          await currentUser.reload().timeout(const Duration(seconds: 3));
          
          // Wait a moment for the state to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check verification status and navigate with timeout
          final authRepository = ref.read(authRepositoryProvider);
          await authRepository.reloadUser().timeout(const Duration(seconds: 3));
          
          if (authRepository.isEmailVerified) {
            Logger.success('Email verified', 'Main');
            // Don't auto-redirect - let user stay on email verification screen
            // They can manually check verification status
          }
        } catch (e) {
          Logger.error('Error applying action code', e, null, 'Main');
          // Even if applying fails, check if email is already verified
          // (Firebase might have processed it automatically)
          try {
            await Future.delayed(const Duration(milliseconds: 500));
          final authRepository = ref.read(authRepositoryProvider);
            await authRepository.reloadUser().timeout(const Duration(seconds: 3));
          
          if (authRepository.isEmailVerified) {
            Logger.success('Email already verified', 'Main');
            // Don't auto-redirect - let user stay on email verification screen
          } else {
            // If verification failed and user is logged in, navigate to email verification screen
            final auth = FirebaseConfig.auth;
            final currentUser = auth.currentUser;
            if (currentUser != null && currentUser.email != null) {
              Logger.info('Verification failed, navigating to email verification screen', 'Main');
              final router = ref.read(routerProvider);
              router.go('${Routes.emailVerification}?email=${Uri.encodeComponent(currentUser.email!)}');
            }
            }
          } catch (e2) {
            Logger.error('Error checking verification status after failure', e2, null, 'Main');
          }
        }
      }
    } catch (e) {
      Logger.error('Error handling email verification link', e, null, 'Main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Listen for user ID changes to save FCM token (must be in build method)
    ref.listen(currentUserIdProvider, (previous, next) {
      if (next != null) {
        Logger.info('User logged in, saving FCM token for user: $next', 'Main');
        // User logged in, ensure token is saved (non-blocking)
        Future.microtask(() async {
          try {
            final fcmService = ref.read(fcmServiceProvider);
            if (fcmService.fcmToken != null) {
              final firestoreService = ref.read(firestoreServiceProvider);
              await firestoreService
                  .updateUserFCMToken(next, fcmService.fcmToken!)
                  .timeout(const Duration(seconds: 5));
              Logger.success('FCM token saved successfully for user: $next', 'Main');
            } else {
              Logger.warning('FCM token is null, cannot save', 'Main');
            }
          } catch (e) {
            Logger.error('Failed to save FCM token after login', e, null, 'Main');
          }
        });
      }
    });

    // Listen for auth state changes to detect email verification (must be in build method)
    ref.listen(authStateProvider, (previous, next) async {
      if (next.value != null) {
        // User is logged in, check if email was just verified
        try {
          final authRepository = ref.read(authRepositoryProvider);
          await authRepository
              .reloadUser()
              .timeout(const Duration(seconds: 3));
          final isVerified = authRepository.isEmailVerified;
          
          // Check if email was just verified (was not verified before)
          final previousUser = previous?.value;
          final wasVerifiedBefore = previousUser?.emailVerified ?? false;
          
          if (isVerified && !wasVerifiedBefore) {
            // Email was just verified, navigate to home
            Logger.success('Email verified, navigating to home', 'Main');
            final router = ref.read(routerProvider);
            router.go(Routes.home);
          }
        } catch (e) {
          Logger.error('Error checking email verification', e, null, 'Main');
        }
      }
    });

    return MaterialApp.router(
      title: 'Cocina en tu Casa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: const Locale('es', 'ES'), // Spanish locale
      supportedLocales: const [
        Locale('es', 'ES'), // Spanish
        Locale('en', 'US'), // English (fallback)
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
