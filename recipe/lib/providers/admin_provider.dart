import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/firestore_service.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

/// Provider for admin controller
final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AdminController(firestoreService, ref);
});

/// Admin controller for handling admin operations
class AdminController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  AdminController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Check if current user is admin
  bool get isAdmin {
    final userAsync = _ref.read(currentUserProvider);
    return userAsync.when(
      data: (user) => user?.isAdmin ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    state = const AsyncValue.loading();

    try {
      await _firestoreService.updateUserRole(userId, role);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      Logger.error('Failed to update user role', e, stackTrace, 'AdminController');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    state = const AsyncValue.loading();

    try {
      await _firestoreService.deleteUser(userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      Logger.error('Failed to delete user', e, stackTrace, 'AdminController');
      rethrow;
    }
  }

  /// Delete recipe as admin
  Future<void> deleteRecipe(String recipeId) async {
    state = const AsyncValue.loading();

    try {
      await _firestoreService.deleteRecipeAsAdmin(recipeId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      Logger.error('Failed to delete recipe', e, stackTrace, 'AdminController');
      rethrow;
    }
  }
}

/// Provider for all users (Admin only)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getAllUsers();
});

/// Provider for admin statistics
final adminStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getAdminStatistics();
});

