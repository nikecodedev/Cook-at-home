import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/ingredient_price_model.dart';
import '../core/utils/logger.dart';

/// Service for managing ingredient prices
class IngredientPriceService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Get price for a canonical ingredient
  Future<IngredientPrice?> getIngredientPrice(String canonicalIngredientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.ingredientPrices)
          .where(FirebaseFields.canonicalIngredientId, isEqualTo: canonicalIngredientId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return IngredientPrice.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get ingredient price', e, null, 'IngredientPriceService');
      return null;
    }
  }

  /// Get price for a canonical ingredient (user-specific override)
  Future<IngredientPrice?> getUserIngredientPrice(
    String canonicalIngredientId,
    String userId,
  ) async {
    try {
      // First check user-specific override
      final userPriceDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('ingredient_prices')
          .doc(canonicalIngredientId)
          .get();

      if (userPriceDoc.exists && userPriceDoc.data() != null) {
        final data = userPriceDoc.data()!;
        // Get base price to merge with
        final basePrice = await getIngredientPrice(canonicalIngredientId);
        
        if (basePrice != null) {
          return basePrice.copyWith(
            userOverridePrice: (data['userOverridePrice'] as num?)?.toDouble(),
          );
        }
      }

      // Fall back to global price
      return await getIngredientPrice(canonicalIngredientId);
    } catch (e) {
      Logger.error('Failed to get user ingredient price', e, null, 'IngredientPriceService');
      return null;
    }
  }

  /// Set or update ingredient price (global average)
  Future<void> setIngredientPrice({
    required String canonicalIngredientId,
    required double averagePrice,
    required String priceUnit,
  }) async {
    try {
      // Check if price already exists
      final existing = await getIngredientPrice(canonicalIngredientId);
      
      if (existing != null) {
        // Update existing
        await _firestore
            .collection(FirebaseCollections.ingredientPrices)
            .doc(existing.id)
            .update({
              'averagePrice': averagePrice,
              'priceUnit': priceUnit,
              'lastUpdated': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });
      } else {
        // Create new
        final now = DateTime.now();
        final price = IngredientPrice(
          id: '', // Will be set by Firestore
          canonicalIngredientId: canonicalIngredientId,
          averagePrice: averagePrice,
          priceUnit: priceUnit,
          lastUpdated: now,
          createdAt: now,
        );

        final docRef = await _firestore
            .collection(FirebaseCollections.ingredientPrices)
            .add(price.toMap());

        Logger.success('Ingredient price created: ${docRef.id}', 'IngredientPriceService');
      }
    } catch (e) {
      Logger.error('Failed to set ingredient price', e, null, 'IngredientPriceService');
      rethrow;
    }
  }

  /// Set user override price
  Future<void> setUserOverridePrice({
    required String userId,
    required String canonicalIngredientId,
    required double? overridePrice, // null to remove override
  }) async {
    try {
      if (overridePrice == null) {
        // Remove override
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection('ingredient_prices')
            .doc(canonicalIngredientId)
            .delete();
      } else {
        // Set override
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection('ingredient_prices')
            .doc(canonicalIngredientId)
            .set({
              'canonicalIngredientId': canonicalIngredientId,
              'userOverridePrice': overridePrice,
              'updatedAt': Timestamp.now(),
            }, SetOptions(merge: true));
      }

      Logger.success('User override price set for ingredient: $canonicalIngredientId', 'IngredientPriceService');
    } catch (e) {
      Logger.error('Failed to set user override price', e, null, 'IngredientPriceService');
      rethrow;
    }
  }

  /// Get prices for multiple ingredients
  Future<Map<String, IngredientPrice>> getIngredientPrices(List<String> canonicalIngredientIds) async {
    try {
      if (canonicalIngredientIds.isEmpty) return {};

      // Firestore 'in' query limit is 10, so we need to batch
      final Map<String, IngredientPrice> prices = {};
      
      for (var i = 0; i < canonicalIngredientIds.length; i += 10) {
        final batch = canonicalIngredientIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(FirebaseCollections.ingredientPrices)
            .where(FirebaseFields.canonicalIngredientId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final price = IngredientPrice.fromFirestore(doc);
          prices[price.canonicalIngredientId] = price;
        }
      }

      return prices;
    } catch (e) {
      Logger.error('Failed to get ingredient prices', e, null, 'IngredientPriceService');
      return {};
    }
  }

  /// Initialize default price for an ingredient (called when ingredient is added to pantry)
  Future<void> initializeDefaultPrice({
    required String canonicalIngredientId,
    double defaultPrice = 0.0,
    String defaultUnit = 'pieces',
  }) async {
    try {
      final existing = await getIngredientPrice(canonicalIngredientId);
      if (existing == null) {
        await setIngredientPrice(
          canonicalIngredientId: canonicalIngredientId,
          averagePrice: defaultPrice,
          priceUnit: defaultUnit,
        );
      }
    } catch (e) {
      Logger.error('Failed to initialize default price', e, null, 'IngredientPriceService');
      // Don't rethrow - this is a non-critical operation
    }
  }
}

