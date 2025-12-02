import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static bool _initialized = false;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      // ignore: avoid_print
      print('✅ Firebase initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Get FirebaseAuth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Get Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Get Firebase Storage instance
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Enable Firestore offline persistence (optional)
  static Future<void> enableOfflinePersistence() async {
    try {
      // Note: Use Settings.persistenceEnabled in configureFirestore instead
      // This method is kept for compatibility
      // ignore: avoid_print
      print('✅ Firestore offline persistence configured via Settings');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Firestore persistence error: $e');
    }
  }

  /// Configure Firestore settings
  static void configureFirestore({
    bool persistenceEnabled = true,
    bool sslEnabled = true,
  }) {
    firestore.settings = Settings(
      persistenceEnabled: persistenceEnabled,
      sslEnabled: sslEnabled,
    );
  }

  /// Set Firebase emulators (for local development)
  static void useEmulators({
    String host = 'localhost',
    int firestorePort = 8080,
    int authPort = 9099,
    int storagePort = 9199,
  }) {
    firestore.useFirestoreEmulator(host, firestorePort);
    auth.useAuthEmulator(host, authPort);
    storage.useStorageEmulator(host, storagePort);
    // ignore: avoid_print
    print('✅ Firebase emulators configured');
  }
}

