import '../models/pantry_item_model.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_price_model.dart';
import '../models/meal_plan_model.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
import '../services/meal_plan_service.dart';
import '../services/firestore/firestore_service.dart';
import '../core/utils/logger.dart';
import '../services/measurement_converter_service.dart' show MeasurementConverterService;

/// Service for calculating pantry value and coverage metrics
class PantryAnalyticsService {
  final IngredientPriceService _priceService;
  final CanonicalIngredientService _canonicalService;
  final MealPlanService? _mealPlanService;
  final FirestoreService? _firestoreService;

  PantryAnalyticsService({
    required IngredientPriceService priceService,
    required CanonicalIngredientService canonicalService,
    MealPlanService? mealPlanService,
    FirestoreService? firestoreService,
  })  : _priceService = priceService,
        _canonicalService = canonicalService,
        _mealPlanService = mealPlanService,
        _firestoreService = firestoreService;

  /// Calculate total pantry value
  Future<PantryValueMetrics> calculatePantryValue(
    List<PantryItem> pantryItems,
    String? userId,
  ) async {
    try {
      double totalValue = 0.0;
      final Map<String, double> itemValues = {};

      // Get all canonical ingredient IDs
      final List<String?> canonicalIds = pantryItems
          .map((item) => item.canonicalIngredientId)
          .where((id) => id != null && id.isNotEmpty)
          .toList();

      // Resolve missing canonical IDs by name
      final List<String> resolvedIds = [];
      for (final item in pantryItems) {
        String? canonicalId = item.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          final canonical = await _canonicalService.findCanonicalIngredientByName(item.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId != null && canonicalId.isNotEmpty) {
          resolvedIds.add(canonicalId);
        }
      }

      // Get prices
      final prices = userId != null
          ? await _getUserPrices(resolvedIds, userId)
          : await _priceService.getIngredientPrices(resolvedIds);

      // Calculate value for each item
      for (final item in pantryItems) {
        String? canonicalId = item.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          final canonical = await _canonicalService.findCanonicalIngredientByName(item.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId == null) {
          continue;
        }

        final price = prices[canonicalId];
        if (price == null) {
          continue;
        }

        // Convert item quantity to price unit (normalize before comparing)
        double value = 0.0;
        try {
          final normalizedItemUnit = MeasurementConverterService.normalizeUnit(item.unit);
          final normalizedPriceUnit = MeasurementConverterService.normalizeUnit(price.priceUnit);

          if (normalizedItemUnit == normalizedPriceUnit) {
            value = price.calculateCost(item.quantity);
          } else {
            final conversion = MeasurementConverterService.convert(
              value: item.quantity,
              fromUnit: item.unit,
              toUnit: price.priceUnit,
            );
            if (conversion != null) {
              value = price.calculateCost(conversion.value);
            }
          }

          totalValue += value;
          itemValues[item.name] = value;
        } catch (e) {
          Logger.warning('Failed to calculate value for item: ${item.name}', 'PantryAnalyticsService');
        }
      }

      return PantryValueMetrics(
        totalValue: totalValue,
        itemValues: itemValues,
        itemCount: pantryItems.length,
      );
    } catch (e) {
      Logger.error('Failed to calculate pantry value', e, null, 'PantryAnalyticsService');
      return PantryValueMetrics(
        totalValue: 0.0,
        itemValues: {},
        itemCount: 0,
      );
    }
  }

  /// Calculate pantry coverage for planned recipes
  Future<PantryCoverageMetrics> calculatePantryCoverage(
    List<PantryItem> pantryItems,
    List<Recipe> plannedRecipes,
    String? userId,
  ) async {
    try {
      if (plannedRecipes.isEmpty) {
        return PantryCoverageMetrics(
          coveragePercentage: 100.0,
          missingIngredients: [],
          availableIngredients: [],
          estimatedMealsAvailable: 0,
        );
      }

      // Collect all required ingredients from recipes
      // We normalize everything to a common unit per ingredient so
      // comparisons are accurate even when recipe uses "cucharadas" and
      // pantry stores "ml".
      final Map<String, double> requiredIngredients = {}; // canonicalId -> total quantity (in normalized unit)
      final Map<String, String> ingredientNames = {}; // canonicalId -> display name
      final Map<String, String> ingredientUnits = {}; // canonicalId -> unit used for aggregation

      for (final recipe in plannedRecipes) {
        for (final ingredient in recipe.ingredients) {
          String? canonicalId = ingredient.canonicalIngredientId;

          if (canonicalId == null || canonicalId.isEmpty) {
            final canonical = await _canonicalService.findCanonicalIngredientByName(ingredient.name);
            canonicalId = canonical?.id;
          }

          if (canonicalId != null && canonicalId.isNotEmpty) {
            final key = canonicalId;
            ingredientNames[key] = ingredient.name;

            if (ingredientUnits.containsKey(key)) {
              // Already have a base unit — convert this ingredient to that unit
              final baseUnit = ingredientUnits[key]!;
              final normalizedIng = MeasurementConverterService.normalizeUnit(ingredient.unit);
              final normalizedBase = MeasurementConverterService.normalizeUnit(baseUnit);

              if (normalizedIng == normalizedBase) {
                requiredIngredients[key] = (requiredIngredients[key] ?? 0) + ingredient.quantity;
              } else {
                final conversion = MeasurementConverterService.convert(
                  value: ingredient.quantity,
                  fromUnit: ingredient.unit,
                  toUnit: baseUnit,
                );
                if (conversion != null) {
                  requiredIngredients[key] = (requiredIngredients[key] ?? 0) + conversion.value;
                } else {
                  // Incompatible — add raw (best effort)
                  requiredIngredients[key] = (requiredIngredients[key] ?? 0) + ingredient.quantity;
                }
              }
            } else {
              // First occurrence — set the base unit
              ingredientUnits[key] = ingredient.unit;
              requiredIngredients[key] = (requiredIngredients[key] ?? 0) + ingredient.quantity;
            }
          }
        }
      }

      // Check pantry availability (convert pantry quantities to the same unit)
      final Map<String, double> availableIngredients = {}; // canonicalId -> available quantity (in same unit as required)
      final List<String> missingIngredients = [];

      for (final item in pantryItems) {
        String? canonicalId = item.canonicalIngredientId;

        if (canonicalId == null || canonicalId.isEmpty) {
          final canonical = await _canonicalService.findCanonicalIngredientByName(item.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId != null && canonicalId.isNotEmpty && requiredIngredients.containsKey(canonicalId)) {
          final baseUnit = ingredientUnits[canonicalId]!;
          final normalizedPantry = MeasurementConverterService.normalizeUnit(item.unit);
          final normalizedBase = MeasurementConverterService.normalizeUnit(baseUnit);

          double qtyInBaseUnit = item.quantity;
          if (normalizedPantry != normalizedBase) {
            final conversion = MeasurementConverterService.convert(
              value: item.quantity,
              fromUnit: item.unit,
              toUnit: baseUnit,
            );
            if (conversion != null) {
              qtyInBaseUnit = conversion.value;
            } else {
              // Incompatible units — cannot count as available
              continue;
            }
          }
          availableIngredients[canonicalId] = (availableIngredients[canonicalId] ?? 0) + qtyInBaseUnit;
        }
      }

      // Determine missing ingredients
      for (final entry in requiredIngredients.entries) {
        final available = availableIngredients[entry.key] ?? 0;
        if (available < entry.value) {
          missingIngredients.add(ingredientNames[entry.key] ?? entry.key);
        }
      }

      // Calculate coverage percentage
      final totalRequired = requiredIngredients.length;
      final totalAvailable = requiredIngredients.keys
          .where((id) => (availableIngredients[id] ?? 0) >= requiredIngredients[id]!)
          .length;
      
      final coveragePercentage = totalRequired > 0
          ? (totalAvailable / totalRequired) * 100.0
          : 100.0;

      // Estimate meals available (simplified: based on coverage)
      final estimatedMealsAvailable = (coveragePercentage / 100.0 * plannedRecipes.length).round();

      return PantryCoverageMetrics(
        coveragePercentage: coveragePercentage,
        missingIngredients: missingIngredients,
        availableIngredients: availableIngredients.keys.toList(),
        estimatedMealsAvailable: estimatedMealsAvailable,
      );
    } catch (e) {
      Logger.error('Failed to calculate pantry coverage', e, null, 'PantryAnalyticsService');
      return PantryCoverageMetrics(
        coveragePercentage: 0.0,
        missingIngredients: [],
        availableIngredients: [],
        estimatedMealsAvailable: 0,
      );
    }
  }

  /// Calculate comprehensive pantry analytics
  /// Includes: total value, estimated meals, coverage %, and efficiency score
  Future<PantryAnalytics> calculateComprehensiveAnalytics(
    List<PantryItem> pantryItems,
    String? userId,
  ) async {
    try {
      // Calculate pantry value
      final valueMetrics = await calculatePantryValue(pantryItems, userId);

      // Get planned recipes from meal plan
      List<Recipe> plannedRecipes = [];
      if (userId != null && _mealPlanService != null && _firestoreService != null) {
        try {
          // Get current week's meal plan
          final now = DateTime.now();
          final monday = _getMonday(now);
          final mealPlan = await _mealPlanService!.getMealPlanForWeek(userId, monday);
          
          if (mealPlan != null) {
            // Fetch all recipes in the meal plan
            final recipeIds = mealPlan.allRecipeIds;
            for (final recipeId in recipeIds) {
              try {
                final recipe = await _firestoreService!.getRecipe(recipeId);
                if (recipe != null) {
                  plannedRecipes.add(recipe);
                }
              } catch (e) {
                Logger.warning('Failed to fetch recipe: $recipeId', 'PantryAnalyticsService');
              }
            }
          }
        } catch (e) {
          Logger.warning('Failed to get meal plan for analytics', 'PantryAnalyticsService');
        }
      }

      // Calculate coverage
      final coverageMetrics = await calculatePantryCoverage(
        pantryItems,
        plannedRecipes,
        userId,
      );

      // Calculate efficiency score
      final efficiencyScore = _calculateEfficiencyScore(
        valueMetrics: valueMetrics,
        coverageMetrics: coverageMetrics,
        pantryItems: pantryItems,
      );

      return PantryAnalytics(
        totalValue: valueMetrics.totalValue,
        estimatedMealsAvailable: coverageMetrics.estimatedMealsAvailable,
        coveragePercentage: coverageMetrics.coveragePercentage,
        efficiencyScore: efficiencyScore,
        itemCount: valueMetrics.itemCount,
        missingIngredients: coverageMetrics.missingIngredients,
      );
    } catch (e) {
      Logger.error('Failed to calculate comprehensive analytics', e, null, 'PantryAnalyticsService');
      return PantryAnalytics(
        totalValue: 0.0,
        estimatedMealsAvailable: 0,
        coveragePercentage: 0.0,
        efficiencyScore: 0.0,
        itemCount: 0,
        missingIngredients: [],
      );
    }
  }

  /// Calculate efficiency score (0-100)
  /// Based on: value utilization, coverage, and pantry health
  double _calculateEfficiencyScore({
    required PantryValueMetrics valueMetrics,
    required PantryCoverageMetrics coverageMetrics,
    required List<PantryItem> pantryItems,
  }) {
    // Factor 1: Coverage (40% weight)
    final coverageScore = coverageMetrics.coveragePercentage * 0.4;

    // Factor 2: Value utilization (30% weight)
    // Higher value with good coverage = better efficiency
    final valueUtilizationScore = coverageMetrics.coveragePercentage > 50
        ? 30.0
        : (coverageMetrics.coveragePercentage / 50.0) * 30.0;

    // Factor 3: Pantry health (30% weight)
    // Based on expired/expiring items
    final expiredCount = pantryItems.where((item) => item.isExpired).length;
    final expiringCount = pantryItems.where((item) => item.isExpiringSoon).length;
    final totalItems = pantryItems.length;
    
    final healthScore = totalItems > 0
        ? ((totalItems - expiredCount - expiringCount * 0.5) / totalItems) * 30.0
        : 30.0;

    return (coverageScore + valueUtilizationScore + healthScore).clamp(0.0, 100.0);
  }

  /// Get Monday of the week for a given date
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  /// Get user-specific prices (with overrides)
  Future<Map<String, IngredientPrice>> _getUserPrices(
    List<String> canonicalIds,
    String userId,
  ) async {
    final Map<String, IngredientPrice> prices = {};
    
    for (final id in canonicalIds) {
      final price = await _priceService.getUserIngredientPrice(id, userId);
      if (price != null) {
        prices[id] = price;
      }
    }
    
    return prices;
  }
}

/// Pantry value metrics
class PantryValueMetrics {
  final double totalValue;
  final Map<String, double> itemValues;
  final int itemCount;

  PantryValueMetrics({
    required this.totalValue,
    required this.itemValues,
    required this.itemCount,
  });
}

/// Pantry coverage metrics
class PantryCoverageMetrics {
  final double coveragePercentage; // 0-100
  final List<String> missingIngredients;
  final List<String> availableIngredients; // canonical IDs
  final int estimatedMealsAvailable;

  PantryCoverageMetrics({
    required this.coveragePercentage,
    required this.missingIngredients,
    required this.availableIngredients,
    required this.estimatedMealsAvailable,
  });
}

/// Comprehensive pantry analytics
class PantryAnalytics {
  final double totalValue; // Total estimated pantry value
  final int estimatedMealsAvailable; // Estimated meals from pantry
  final double coveragePercentage; // Coverage % for planned recipes (0-100)
  final double efficiencyScore; // Efficiency score (0-100)
  final int itemCount; // Total number of pantry items
  final List<String> missingIngredients; // Missing ingredients for planned recipes

  PantryAnalytics({
    required this.totalValue,
    required this.estimatedMealsAvailable,
    required this.coveragePercentage,
    required this.efficiencyScore,
    required this.itemCount,
    required this.missingIngredients,
  });
}

