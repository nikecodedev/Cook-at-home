import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/firestore_service.dart';
import '../models/pantry_item_model.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

/// Provider for pantry items stream
final pantryItemsStreamProvider = StreamProvider<List<PantryItem>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamPantryItems(userId);
});

/// Provider for pantry loading state
final pantryLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for pantry error message
final pantryErrorProvider = StateProvider<String?>((ref) => null);

/// Pantry controller for handling pantry operations
class PantryController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  PantryController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Add a new pantry item
  Future<void> addPantryItem(PantryItem item) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(pantryErrorProvider.notifier).state = null;

    try {
      await _firestoreService.addPantryItem(userId, item);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(pantryErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update an existing pantry item
  Future<void> updatePantryItem(PantryItem item) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(pantryErrorProvider.notifier).state = null;

    try {
      await _firestoreService.updatePantryItem(userId, item);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(pantryErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Delete a pantry item
  Future<void> deletePantryItem(String itemId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(pantryErrorProvider.notifier).state = null;

    try {
      await _firestoreService.deletePantryItem(userId, itemId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(pantryErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for PantryController
final pantryControllerProvider =
    StateNotifierProvider<PantryController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PantryController(firestoreService, ref);
});

