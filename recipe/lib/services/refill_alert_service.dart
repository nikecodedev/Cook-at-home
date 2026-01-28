import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/refill_alert_model.dart';
import '../models/pantry_item_model.dart';
import '../models/recipe_model.dart';
import '../models/meal_plan_model.dart';
import '../services/firestore/firestore_service.dart';
import '../services/ingredient_price_service.dart';
import '../services/meal_plan_service.dart';
import '../core/utils/logger.dart';

/// Service for managing smart refill alerts
class RefillAlertService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirestoreService? _firestoreService;
  final IngredientPriceService? _ingredientPriceService;
  final MealPlanService? _mealPlanService;

  RefillAlertService({
    FirestoreService? firestoreService,
    IngredientPriceService? ingredientPriceService,
    MealPlanService? mealPlanService,
  })  : _firestoreService = firestoreService,
        _ingredientPriceService = ingredientPriceService,
        _mealPlanService = mealPlanService;

  /// Generate comprehensive smart refill alerts
  /// Considers: low quantity, usage frequency, and price index
  Future<List<RefillAlert>> generateSmartRefillAlerts(
    String userId,
    List<PantryItem> pantryItems,
  ) async {
    try {
      final List<RefillAlert> alerts = [];
      final now = DateTime.now();

      // Calculate usage frequency for all ingredients
      final usageFrequency = await _calculateUsageFrequency(userId);

      // Calculate price indices for ingredients
      final priceIndices = await _calculatePriceIndices(userId, pantryItems);

      // Generate alerts for each pantry item
      for (final item in pantryItems) {
        if (item.canonicalIngredientId == null || item.canonicalIngredientId!.isEmpty) {
          continue;
        }

        final canonicalId = item.canonicalIngredientId!;
        final usageScore = usageFrequency[canonicalId] ?? 0.0;
        final priceIndex = priceIndices[canonicalId];

        // Alert 1: Low quantity (usage-aware threshold)
        final lowQuantityAlert = await _checkLowQuantityAlert(
          userId,
          item,
          usageScore,
        );
        if (lowQuantityAlert != null) {
          alerts.add(lowQuantityAlert);
        }

        // Alert 2: High usage frequency (frequently used but low stock)
        if (usageScore > 0.7 && item.quantity < 2.0) {
          final existing = await getActiveAlert(userId, canonicalId, 'high_usage');
          if (existing == null) {
            final alert = RefillAlert(
              id: '',
              userId: userId,
              canonicalIngredientId: canonicalId,
              ingredientName: item.name,
              reason: 'high_usage',
              currentQuantity: item.quantity,
              currentUnit: item.unit,
              createdAt: now,
            );
            final alertId = await createRefillAlert(alert);
            alerts.add(alert.copyWith(id: alertId));
          }
        }

        // Alert 3: Price index (good price opportunity)
        if (priceIndex != null && priceIndex < 0.8) {
          final existing = await getActiveAlert(userId, canonicalId, 'price_index');
          if (existing == null) {
            final alert = RefillAlert(
              id: '',
              userId: userId,
              canonicalIngredientId: canonicalId,
              ingredientName: item.name,
              reason: 'price_index',
              priceIndex: priceIndex,
              createdAt: now,
            );
            final alertId = await createRefillAlert(alert);
            alerts.add(alert.copyWith(id: alertId));
          }
        }
      }

      return alerts;
    } catch (e) {
      Logger.error('Failed to generate smart refill alerts', e, null, 'RefillAlertService');
      return [];
    }
  }

  /// Generate refill alerts based on pantry depletion (legacy method)
  Future<List<RefillAlert>> generateDepletionAlerts(
    String userId,
    List<PantryItem> pantryItems,
  ) async {
    // Use smart alerts instead
    return generateSmartRefillAlerts(userId, pantryItems);
  }

  /// Calculate usage frequency for ingredients
  /// Returns map of canonicalIngredientId -> usage score (0.0 to 1.0)
  Future<Map<String, double>> _calculateUsageFrequency(String userId) async {
    final Map<String, int> usageCounts = {};
    final Map<String, double> usageScores = {};

    if (_firestoreService == null) {
      return usageScores;
    }

    try {
      // Get current week's meal plan
      final now = DateTime.now();
      final monday = _getMonday(now);
      
      // Get meal plans from last 4 weeks to calculate frequency
      for (int weekOffset = 0; weekOffset < 4; weekOffset++) {
        final weekStart = monday.subtract(Duration(days: 7 * weekOffset));
        
        // Get recipes from user's recipes and meal plans
        try {
          // Count from user's recipes
          final recipes = await _firestoreService!.getUserRecipes(userId);
          for (final recipe in recipes) {
            for (final ingredient in recipe.ingredients) {
              final canonicalId = ingredient.canonicalIngredientId;
              if (canonicalId != null && canonicalId.isNotEmpty) {
                usageCounts[canonicalId] = (usageCounts[canonicalId] ?? 0) + 1;
              }
            }
          }
          
          // Count from meal plans (last 4 weeks)
          if (_mealPlanService != null && _firestoreService != null) {
            try {
              for (int weekOffset = 0; weekOffset < 4; weekOffset++) {
                final weekStart = monday.subtract(Duration(days: 7 * weekOffset));
                final mealPlan = await _mealPlanService!.getMealPlanForWeek(userId, weekStart);
                
                if (mealPlan != null) {
                  // Get recipes from meal plan
                  final recipeIds = mealPlan.allRecipeIds;
                  for (final recipeId in recipeIds) {
                    try {
                      final recipe = await _firestoreService!.getRecipe(recipeId);
                      if (recipe != null) {
                        for (final ingredient in recipe.ingredients) {
                          final canonicalId = ingredient.canonicalIngredientId;
                          if (canonicalId != null && canonicalId.isNotEmpty) {
                            usageCounts[canonicalId] = (usageCounts[canonicalId] ?? 0) + 1;
                          }
                        }
                      }
                    } catch (e) {
                      // Skip failed recipes
                    }
                  }
                }
              }
            } catch (e) {
              Logger.warning('Failed to get meal plans for usage tracking: $e', 'RefillAlertService');
            }
          }
        } catch (e) {
          Logger.warning('Failed to get recipes for usage tracking: $e', 'RefillAlertService');
        }
      }

      // Normalize usage counts to scores (0.0 to 1.0)
      final maxCount = usageCounts.values.isNotEmpty 
          ? usageCounts.values.reduce((a, b) => a > b ? a : b) 
          : 1;
      
      for (final entry in usageCounts.entries) {
        usageScores[entry.key] = entry.value / maxCount;
      }

      return usageScores;
    } catch (e) {
      Logger.warning('Failed to calculate usage frequency: $e', 'RefillAlertService');
      return usageScores;
    }
  }

  /// Calculate price indices for ingredients
  /// Returns map of canonicalIngredientId -> price index (0.0 to 1.0, lower = better price)
  /// Compares current price to market average
  Future<Map<String, double>> _calculatePriceIndices(
    String userId,
    List<PantryItem> pantryItems,
  ) async {
    final Map<String, double> priceIndices = {};

    if (_ingredientPriceService == null) {
      return priceIndices;
    }

    try {
      // Get average prices for all ingredients
      final canonicalIds = pantryItems
          .map((item) => item.canonicalIngredientId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (canonicalIds.isEmpty) {
        return priceIndices;
      }

      final prices = await _ingredientPriceService!.getIngredientPrices(canonicalIds);
      
      if (prices.isEmpty) {
        return priceIndices;
      }

      // Calculate market statistics
      final priceValues = prices.values
          .map((price) => price.effectivePrice)
          .where((p) => p > 0)
          .toList();
      
      if (priceValues.isEmpty) {
        return priceIndices;
      }

      final averagePrice = priceValues.reduce((a, b) => a + b) / priceValues.length;
      final minPrice = priceValues.reduce((a, b) => a < b ? a : b);
      final maxPrice = priceValues.reduce((a, b) => a > b ? a : b);
      final priceRange = maxPrice - minPrice;

      // Calculate price index for each ingredient
      // Index represents how good the price is relative to market
      for (final entry in prices.entries) {
        final price = entry.value.effectivePrice;
        if (priceRange > 0) {
          // Normalize: lower price = lower index (better opportunity)
          // Price at min = 0.0 (best), price at max = 1.0 (worst)
          priceIndices[entry.key] = (price - minPrice) / priceRange;
        } else {
          // If all prices are the same, neutral index
          priceIndices[entry.key] = 0.5;
        }
      }

      return priceIndices;
    } catch (e) {
      Logger.warning('Failed to calculate price indices: $e', 'RefillAlertService');
      return priceIndices;
    }
  }

  /// Check if item should trigger low quantity alert
  /// Uses usage-aware threshold
  Future<RefillAlert?> _checkLowQuantityAlert(
    String userId,
    PantryItem item,
    double usageScore,
  ) async {
    // Usage-aware threshold: higher usage = lower threshold
    // High usage (0.7+): alert at 30% remaining
    // Medium usage (0.3-0.7): alert at 20% remaining
    // Low usage (<0.3): alert at 10% remaining
    double threshold;
    if (usageScore >= 0.7) {
      threshold = 0.3; // Alert early for frequently used items
    } else if (usageScore >= 0.3) {
      threshold = 0.2;
    } else {
      threshold = 0.1; // Alert later for rarely used items
    }

    // Simplified: assume typical quantity is 5.0 units
    // In production, track historical average quantities
    const typicalQuantity = 5.0;
    final lowStockThreshold = typicalQuantity * threshold;
    final isLowStock = item.quantity < lowStockThreshold;

    if (isLowStock) {
      final existing = await getActiveAlert(
        userId,
        item.canonicalIngredientId!,
        'depletion',
      );

      if (existing == null) {
        return RefillAlert(
          id: '',
          userId: userId,
          canonicalIngredientId: item.canonicalIngredientId!,
          ingredientName: item.name,
          reason: 'depletion',
          currentQuantity: item.quantity,
          currentUnit: item.unit,
          createdAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  /// Get Monday of the week for a given date
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  /// Get active refill alerts for a user
  Future<List<RefillAlert>> getActiveRefillAlerts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RefillAlert.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get active refill alerts', e, null, 'RefillAlertService');
      return [];
    }
  }

  /// Get active alert for a specific ingredient
  Future<RefillAlert?> getActiveAlert(
    String userId,
    String canonicalIngredientId,
    String reason,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .where('canonicalIngredientId', isEqualTo: canonicalIngredientId)
          .where('reason', isEqualTo: reason)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RefillAlert.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get active alert', e, null, 'RefillAlertService');
      return null;
    }
  }

  /// Create a refill alert
  Future<String> createRefillAlert(RefillAlert alert) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseCollections.users)
          .doc(alert.userId)
          .collection(FirebaseCollections.refillAlerts)
          .add(alert.toMap());

      Logger.success('Refill alert created: ${docRef.id}', 'RefillAlertService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create refill alert', e, null, 'RefillAlertService');
      rethrow;
    }
  }

  /// Dismiss a refill alert
  Future<void> dismissRefillAlert(String userId, String alertId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .doc(alertId)
          .update({
            'isActive': false,
            'dismissedAt': Timestamp.now(),
          });

      Logger.success('Refill alert dismissed: $alertId', 'RefillAlertService');
    } catch (e) {
      Logger.error('Failed to dismiss refill alert', e, null, 'RefillAlertService');
      rethrow;
    }
  }

  /// Stream active refill alerts
  Stream<List<RefillAlert>> streamActiveRefillAlerts(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.refillAlerts)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return RefillAlert.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse refill alert', e, null, 'RefillAlertService');
              return null;
            }
          })
          .whereType<RefillAlert>()
          .toList();
    }).handleError((error) {
      Logger.error('Error in refill alerts stream', error, null, 'RefillAlertService');
      return <RefillAlert>[];
    });
  }
}



