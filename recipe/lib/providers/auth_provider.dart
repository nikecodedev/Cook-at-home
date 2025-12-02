import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for current user profile
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  // If no user is signed in, return null
  if (authState.value == null) {
    return Stream.value(null);
  }

  // Stream the user profile from Firestore
  return authRepository.streamCurrentUserProfile();
});

/// Provider to check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// Provider for auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for auth error message
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Auth controller for handling authentication operations
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref)
      : super(const AsyncValue.data(null));

  /// Register with email and password
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    UserPreferences? preferences,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
        preferences: preferences,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Resend email verification
  Future<void> resendVerificationEmail() async {
    state = const AsyncValue.loading();
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authRepository.resendVerificationEmail();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository, ref);
});

