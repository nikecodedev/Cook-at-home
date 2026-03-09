import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/ingredient_price_model.dart';
import '../core/utils/logger.dart';
export '../models/ingredient_price_model.dart' show PricingType;

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
  /// Checks user's ingredient_prices first, then falls back to global
  Future<IngredientPrice?> getUserIngredientPrice(
    String canonicalIngredientId,
    String userId,
  ) async {
    try {
      // First check user-specific price (override or user-entered)
      final userPriceDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection('ingredient_prices')
          .doc(canonicalIngredientId)
          .get();

      if (userPriceDoc.exists && userPriceDoc.data() != null) {
        final data = userPriceDoc.data()!;
        final userPrice = (data['userOverridePrice'] as num?)?.toDouble();
        final userPriceUnit = data['priceUnit'] as String?;
        final userPricingType = PricingType.fromJson(data['pricingType'] as String?);
        final userPackageSize = data['packageSize'] != null ? (data['packageSize'] as num).toDouble() : null;
        final userPackageUnit = data['packageUnit'] as String?;
        // Get base price to merge with
        final basePrice = await getIngredientPrice(canonicalIngredientId);

        if (basePrice != null) {
          return basePrice.copyWith(
            userOverridePrice: userPrice,
            pricingType: userPricingType,
            packageSize: userPackageSize,
            packageUnit: userPackageUnit,
          );
        }
        // User has price but no global base - build synthetic IngredientPrice from user doc
        if (userPrice != null && userPrice > 0) {
          final now = DateTime.now();
          return IngredientPrice(
            id: userPriceDoc.id,
            canonicalIngredientId: canonicalIngredientId,
            averagePrice: userPrice,
            priceUnit: userPriceUnit ?? 'pieces',
            userOverridePrice: userPrice,
            pricingType: userPricingType,
            packageSize: userPackageSize,
            packageUnit: userPackageUnit,
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
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
    PricingType pricingType = PricingType.perUnit,
    double? packageSize,
    String? packageUnit,
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
              'pricingType': pricingType.toJson(),
              'packageSize': packageSize,
              'packageUnit': packageUnit,
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
          pricingType: pricingType,
          packageSize: packageSize,
          packageUnit: packageUnit,
          updatedAt: now,
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
  /// [priceUnit] - when provided, enables price sync when no global base exists
  Future<void> setUserOverridePrice({
    required String userId,
    required String canonicalIngredientId,
    required double? overridePrice, // null to remove override
    String? priceUnit, // Required for Recipe/Shopping List sync when no base price
    PricingType? pricingType,
    double? packageSize,
    String? packageUnit,
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
        // Set override (with priceUnit for sync across Pantry → Recipe → Shopping List)
        final data = <String, dynamic>{
          'canonicalIngredientId': canonicalIngredientId,
          'userOverridePrice': overridePrice,
          'updatedAt': Timestamp.now(),
        };
        if (priceUnit != null && priceUnit.isNotEmpty) {
          data['priceUnit'] = priceUnit;
        }
        if (pricingType != null) {
          data['pricingType'] = pricingType.toJson();
        }
        if (packageSize != null) {
          data['packageSize'] = packageSize;
        }
        if (packageUnit != null) {
          data['packageUnit'] = packageUnit;
        }
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection('ingredient_prices')
            .doc(canonicalIngredientId)
            .set(data, SetOptions(merge: true));
      }

      Logger.success('User override price set for ingredient: $canonicalIngredientId', 'IngredientPriceService');
    } catch (e) {
      Logger.error('Failed to set user override price', e, null, 'IngredientPriceService');
      rethrow;
    }
  }

  /// Set or update user ingredient price (unit price for cost calculations)
  /// Ensures price sync: Pantry → Recipe → Shopping List
  Future<void> setUserIngredientPrice({
    required String userId,
    required String canonicalIngredientId,
    required double unitPrice,
    required String priceUnit, // g, kg, ml, L, pcs
    PricingType pricingType = PricingType.perUnit,
    double? packageSize,
    String? packageUnit,
  }) async {
    try {
      // Create/update global base so Recipe/Shopping List can use it
      await setIngredientPrice(
        canonicalIngredientId: canonicalIngredientId,
        averagePrice: unitPrice,
        priceUnit: priceUnit,
        pricingType: pricingType,
        packageSize: packageSize,
        packageUnit: packageUnit,
      );
      // Also set user override so user's prices take precedence
      await setUserOverridePrice(
        userId: userId,
        canonicalIngredientId: canonicalIngredientId,
        overridePrice: unitPrice,
        priceUnit: priceUnit,
        pricingType: pricingType,
        packageSize: packageSize,
        packageUnit: packageUnit,
      );
    } catch (e) {
      Logger.error('Failed to set user ingredient price', e, null, 'IngredientPriceService');
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



