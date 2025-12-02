import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/firestore_service.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart';

/// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// Provider for current user profile stream
final profileStreamProvider = StreamProvider<ProfileModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserProfile(userId);
});

/// Provider for current user profile (async value)
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Future.value(null);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserProfile(userId);
});

/// Provider for profile loading state
final profileLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for profile error message
final profileErrorProvider = StateProvider<String?>((ref) => null);

/// Profile controller for handling profile operations
class ProfileController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  ProfileController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Create user profile
  Future<void> createProfile({
    required String userId,
    required String name,
    required String email,
    String? location,
    String unitPreference = 'metric',
    int servingSize = 4,
    List<HouseholdMember> householdMembers = const [],
  }) async {
    state = const AsyncValue.loading();
    _ref.read(profileErrorProvider.notifier).state = null;

    try {
      await _firestoreService.createUserProfile(
        userId: userId,
        name: name,
        email: email,
        location: location,
        unitPreference: unitPreference,
        servingSize: servingSize,
        householdMembers: householdMembers,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(profileErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? location,
    String? unitPreference,
    int? servingSize,
    List<HouseholdMember>? householdMembers,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(profileErrorProvider.notifier).state = null;

    try {
      await _firestoreService.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        location: location,
        unitPreference: unitPreference,
        servingSize: servingSize,
        householdMembers: householdMembers,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(profileErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for ProfileController
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProfileController(firestoreService, ref);
});

