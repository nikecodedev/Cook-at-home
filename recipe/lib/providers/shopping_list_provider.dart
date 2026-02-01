import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/firestore_service.dart';
import '../models/shopping_list_model.dart';
import '../models/user_store_model.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';
import 'pantry_provider.dart';

/// Provider for shopping lists stream
final shoppingListsStreamProvider = StreamProvider<List<ShoppingList>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamShoppingLists(userId);
});

/// Provider for shopping list items stream
final shoppingListItemsStreamProvider =
    StreamProvider.family<List<ShoppingListItem>, String>((ref, listId) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamShoppingListItems(userId, listId);
});

/// Provider for shopping list loading state
final shoppingListLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for shopping list error message
final shoppingListErrorProvider = StateProvider<String?>((ref) => null);

/// Shopping list controller for handling shopping list operations
class ShoppingListController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  ShoppingListController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Generate shopping list from recipe
  Future<String> generateShoppingList(Recipe recipe) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      // Get pantry items
      final pantryItems = await _firestoreService.getPantryItems(userId);

      // Generate shopping list
      final listId = await _firestoreService.generateShoppingList(
        userId: userId,
        recipe: recipe,
        pantryItems: pantryItems,
      );

      state = const AsyncValue.data(null);
      return listId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update shopping item checked status
  Future<void> updateItemStatus({
    required String listId,
    required String itemId,
    required bool isChecked,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.updateShoppingItemStatus(
        userId: userId,
        listId: listId,
        itemId: itemId,
        isChecked: isChecked,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update shopping list name
  Future<void> updateShoppingList({
    required String listId,
    required String name,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.updateShoppingList(
        userId: userId,
        listId: listId,
        name: name,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update shopping list item
  Future<void> updateShoppingItem({
    required String listId,
    required String itemId,
    required String name,
    required double quantity,
    required String unit,
    String? amazonLink,
    String? walmartLink,
    List<CustomStoreLink>? customStores,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.updateShoppingItem(
        userId: userId,
        listId: listId,
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        amazonLink: amazonLink,
        walmartLink: walmartLink,
        customStores: customStores,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Delete shopping list item
  Future<void> deleteShoppingItem({
    required String listId,
    required String itemId,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.deleteShoppingItem(
        userId: userId,
        listId: listId,
        itemId: itemId,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Delete shopping list
  Future<void> deleteShoppingList(String listId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.deleteShoppingList(userId, listId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Archive or unarchive shopping list
  Future<void> archiveShoppingList({
    required String listId,
    required bool isArchived,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(shoppingListErrorProvider.notifier).state = null;

    try {
      await _firestoreService.archiveShoppingList(
        userId: userId,
        listId: listId,
        isArchived: isArchived,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(shoppingListErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for ShoppingListController
final shoppingListControllerProvider =
    StateNotifierProvider<ShoppingListController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingListController(firestoreService, ref);
});

