import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import '../models/ingredient_price_model.dart';
import '../services/recipe_cost_service.dart';
import '../services/firestore/firestore_service.dart';
import '../services/pantry_analytics_service.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
import '../services/measurement_converter_service.dart' show MeasurementConverterService;
import '../core/utils/logger.dart';

/// Service for calculating meal plan costs
class MealPlanCostService {
  final RecipeCostService _recipeCostService;
  final FirestoreService _firestoreService;
  final PantryAnalyticsService? _pantryAnalyticsService;
  final IngredientPriceService? _ingredientPriceService;
  final CanonicalIngredientService? _canonicalIngredientService;

  MealPlanCostService({
    required RecipeCostService recipeCostService,
    required FirestoreService firestoreService,
    PantryAnalyticsService? pantryAnalyticsService,
    IngredientPriceService? ingredientPriceService,
    CanonicalIngredientService? canonicalIngredientService,
  })  : _recipeCostService = recipeCostService,
        _firestoreService = firestoreService,
        _pantryAnalyticsService = pantryAnalyticsService,
        _ingredientPriceService = ingredientPriceService,
        _canonicalIngredientService = canonicalIngredientService;

  /// Calculate weekly meal plan cost
  ///
  /// Key design decisions:
  /// - Uses recipeIdCounts (not deduplicated allRecipeIds) so a recipe
  ///   appearing 3 times in the week counts 3× toward cost.
  /// - Missing ingredient cost uses price.calculateCost() with proper unit
  ///   conversion, NOT raw quantity × effectivePrice.
  /// - Quantities are normalized to the price unit before comparison/cost.
  Future<MealPlanCostCalculation> calculateMealPlanCost(
    MealPlan mealPlan,
    String userId,
  ) async {
    try {
      // Use recipeIdCounts so we know how many times each recipe appears
      final recipeIdCounts = mealPlan.recipeIdCounts;
      if (recipeIdCounts.isEmpty) {
        return MealPlanCostCalculation(
          totalWeeklyCost: 0.0,
          missingIngredientCost: 0.0,
          dailyCosts: {},
          costPerDay: 0.0,
        );
      }

      // Fetch each unique recipe once
      final Map<String, Recipe> recipeMap = {};
      for (final recipeId in recipeIdCounts.keys) {
        try {
          final recipe = await _firestoreService.getRecipe(recipeId);
          if (recipe != null) {
            recipeMap[recipeId] = recipe;
          }
        } catch (e) {
          Logger.warning('Failed to fetch recipe: $recipeId', 'MealPlanCostService');
        }
      }

      // Calculate cost per recipe (once), then multiply by occurrence count
      final Map<String, double> recipeCosts = {};
      double totalWeeklyCost = 0.0;

      for (final entry in recipeIdCounts.entries) {
        final recipe = recipeMap[entry.key];
        if (recipe == null) continue;
        final count = entry.value;

        final costCalc = await _recipeCostService.calculateRecipeCost(recipe, userId);
        recipeCosts[recipe.id] = costCalc.totalCost;
        // Multiply by how many times this recipe appears in the plan
        totalWeeklyCost += costCalc.totalCost * count;
      }

      // Calculate daily costs (from meal slots and legacy dailyRecipes)
      final Map<String, double> dailyCosts = {};

      for (final dayKey in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
        double dayCost = 0.0;
        final dayMeals = mealPlan.dailyMeals[dayKey] ?? {};
        for (final recipeId in dayMeals.values) {
          if (recipeId != null && recipeId.isNotEmpty) {
            dayCost += recipeCosts[recipeId] ?? 0.0;
          }
        }
        // Also include legacy dailyRecipes for backward compatibility
        final legacyRecipes = mealPlan.dailyRecipes[dayKey] ?? [];
        for (final recipeId in legacyRecipes) {
          dayCost += recipeCosts[recipeId] ?? 0.0;
        }
        if (dayCost > 0) {
          dailyCosts[dayKey] = dayCost;
        }
      }

      // Calculate average cost per day
      final costPerDay = dailyCosts.values.isNotEmpty
          ? dailyCosts.values.reduce((a, b) => a + b) / dailyCosts.length
          : 0.0;

      // ── Calculate missing ingredient cost ──
      // This is the cost of ingredients NOT in the pantry that the user needs to buy.
      // We aggregate all ingredients (scaled by recipe occurrence), convert units
      // to the price unit, subtract pantry, then use price.calculateCost() for
      // proportional pricing.
      double missingIngredientCost = 0.0;
      if (_ingredientPriceService != null) {
        try {
          final pantryItems = await _firestoreService.getPantryItems(userId);

          // ── Step 1: Aggregate required ingredients in PRICE UNIT ──
          // canonicalId -> { 'quantity': double (in price unit), 'priceUnit': String }
          final Map<String, _AggregatedIngredient> required = {};

          for (final entry in recipeIdCounts.entries) {
            final recipe = recipeMap[entry.key];
            if (recipe == null) continue;
            final multiplier = entry.value;

            for (final ingredient in recipe.ingredients) {
              String? canonicalId = ingredient.canonicalIngredientId;
              if ((canonicalId == null || canonicalId.isEmpty) && _canonicalIngredientService != null) {
                final canonical = await _canonicalIngredientService!
                    .findCanonicalIngredientByName(ingredient.name);
                canonicalId = canonical?.id;
              }
              if (canonicalId == null || canonicalId.isEmpty) continue;

              // Get the price so we know what unit to convert to
              final price = await _ingredientPriceService!.getUserIngredientPrice(canonicalId, userId) ??
                  await _ingredientPriceService!.getIngredientPrice(canonicalId);

              final scaledQty = ingredient.quantity * multiplier;

              if (price == null) {
                // No price info — skip (cannot calculate cost)
                continue;
              }

              // Convert ingredient quantity to the price's unit
              double qtyInPriceUnit = scaledQty;
              final normalizedIngUnit = MeasurementConverterService.normalizeUnit(ingredient.unit);
              final normalizedPriceUnit = MeasurementConverterService.normalizeUnit(price.priceUnit);

              if (normalizedIngUnit != normalizedPriceUnit) {
                final conversion = MeasurementConverterService.convert(
                  value: scaledQty,
                  fromUnit: ingredient.unit,
                  toUnit: price.priceUnit,
                );
                if (conversion != null) {
                  qtyInPriceUnit = conversion.value;
                } else {
                  // Incompatible units — skip this ingredient
                  Logger.warning(
                    'MealPlanCost: cannot convert "${ingredient.unit}" to "${price.priceUnit}" for ${ingredient.name}',
                    'MealPlanCostService',
                  );
                  continue;
                }
              }

              if (required.containsKey(canonicalId)) {
                required[canonicalId]!.quantity += qtyInPriceUnit;
              } else {
                required[canonicalId] = _AggregatedIngredient(
                  quantity: qtyInPriceUnit,
                  priceUnit: price.priceUnit,
                  price: price,
                );
              }
            }
          }

          // ── Step 2: Aggregate pantry availability in PRICE UNIT ──
          final Map<String, double> available = {};
          for (final item in pantryItems) {
            String? canonicalId = item.canonicalIngredientId;
            if ((canonicalId == null || canonicalId.isEmpty) && _canonicalIngredientService != null) {
              final canonical = await _canonicalIngredientService!
                  .findCanonicalIngredientByName(item.name);
              canonicalId = canonical?.id;
            }
            if (canonicalId == null || canonicalId.isEmpty) continue;

            final req = required[canonicalId];
            if (req == null) continue; // Not needed by any recipe

            // Convert pantry quantity to the price unit
            double pantryQtyInPriceUnit = item.quantity;
            final normalizedPantryUnit = MeasurementConverterService.normalizeUnit(item.unit);
            final normalizedPriceUnit = MeasurementConverterService.normalizeUnit(req.priceUnit);

            if (normalizedPantryUnit != normalizedPriceUnit) {
              final conversion = MeasurementConverterService.convert(
                value: item.quantity,
                fromUnit: item.unit,
                toUnit: req.priceUnit,
              );
              if (conversion != null) {
                pantryQtyInPriceUnit = conversion.value;
              } else {
                // Incompatible units — treat as unavailable
                continue;
              }
            }

            available[canonicalId] = (available[canonicalId] ?? 0) + pantryQtyInPriceUnit;
          }

          // ── Step 3: Calculate cost of missing quantities ──
          for (final entry in required.entries) {
            final canonicalId = entry.key;
            final req = entry.value;
            final avail = available[canonicalId] ?? 0;

            if (avail >= req.quantity) continue; // Fully covered

            final missingQty = req.quantity - avail;
            // Use calculateCost() which handles perPackage proportional math
            missingIngredientCost += req.price.calculateCost(missingQty);
          }
        } catch (e) {
          Logger.warning('Failed to calculate missing ingredient cost: $e', 'MealPlanCostService');
        }
      }

      return MealPlanCostCalculation(
        totalWeeklyCost: totalWeeklyCost,
        missingIngredientCost: missingIngredientCost,
        dailyCosts: dailyCosts,
        costPerDay: costPerDay,
      );
    } catch (e) {
      Logger.error('Failed to calculate meal plan cost', e, null, 'MealPlanCostService');
      return MealPlanCostCalculation(
        totalWeeklyCost: 0.0,
        missingIngredientCost: 0.0,
        dailyCosts: {},
        costPerDay: 0.0,
      );
    }
  }
}

/// Internal helper to track aggregated ingredient quantities in a common unit
class _AggregatedIngredient {
  double quantity; // In priceUnit
  final String priceUnit;
  final IngredientPrice price;

  _AggregatedIngredient({
    required this.quantity,
    required this.priceUnit,
    required this.price,
  });
}

/// Result of meal plan cost calculation
class MealPlanCostCalculation {
  final double totalWeeklyCost;
  final double missingIngredientCost; // Cost to purchase missing ingredients
  final Map<String, double> dailyCosts; // day -> cost
  final double costPerDay; // Average cost per day

  MealPlanCostCalculation({
    required this.totalWeeklyCost,
    required this.missingIngredientCost,
    required this.dailyCosts,
    required this.costPerDay,
  });
}



