import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import '../services/recipe_cost_service.dart';
import '../services/firestore/firestore_service.dart';
import '../services/pantry_analytics_service.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
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
  Future<MealPlanCostCalculation> calculateMealPlanCost(
    MealPlan mealPlan,
    String userId,
  ) async {
    try {
      // Get all recipes in the meal plan
      final recipeIds = mealPlan.allRecipeIds;
      if (recipeIds.isEmpty) {
        return MealPlanCostCalculation(
          totalWeeklyCost: 0.0,
          missingIngredientCost: 0.0,
          dailyCosts: {},
          costPerDay: 0.0,
        );
      }

      // Fetch recipes
      final List<Recipe> recipes = [];
      for (final recipeId in recipeIds) {
        try {
          final recipe = await _firestoreService.getRecipe(recipeId);
          if (recipe != null) {
            recipes.add(recipe);
          }
        } catch (e) {
          Logger.warning('Failed to fetch recipe: $recipeId', 'MealPlanCostService');
        }
      }

      // Calculate cost for each recipe
      final Map<String, double> recipeCosts = {};
      double totalWeeklyCost = 0.0;

      for (final recipe in recipes) {
        final costCalc = await _recipeCostService.calculateRecipeCost(recipe, userId);
        recipeCosts[recipe.id] = costCalc.totalCost;
        totalWeeklyCost += costCalc.totalCost;
      }

      // Calculate daily costs (from meal slots and legacy dailyRecipes)
      final Map<String, double> dailyCosts = {};
      
      // Calculate from meal slots
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

      // Calculate missing ingredient cost
      double missingIngredientCost = 0.0;
      if (_pantryAnalyticsService != null) {
        try {
          // Get pantry items
          final pantryItems = await _firestoreService.getPantryItems(userId);
          
          // Calculate coverage to get missing ingredient cost
          final coverageMetrics = await _pantryAnalyticsService!.calculatePantryCoverage(
            pantryItems,
            recipes,
            userId,
          );
          
          // Calculate cost of missing ingredients
          // Aggregate required ingredients from all recipes
          final Map<String, double> requiredIngredients = {}; // canonicalId -> total quantity
          for (final recipe in recipes) {
            for (final ingredient in recipe.ingredients) {
              String? canonicalId = ingredient.canonicalIngredientId;
              if (canonicalId == null || canonicalId.isEmpty) {
                if (_canonicalIngredientService != null) {
                  final canonical = await _canonicalIngredientService!
                      .findCanonicalIngredientByName(ingredient.name);
                  canonicalId = canonical?.id;
                }
              }
              if (canonicalId != null && canonicalId.isNotEmpty) {
                requiredIngredients[canonicalId] = 
                    (requiredIngredients[canonicalId] ?? 0) + ingredient.quantity;
              }
            }
          }
          
          // Get available ingredients from pantry
          final Map<String, double> availableIngredients = {};
          for (final item in pantryItems) {
            String? canonicalId = item.canonicalIngredientId;
            if (canonicalId == null || canonicalId.isEmpty) {
              if (_canonicalIngredientService != null) {
                final canonical = await _canonicalIngredientService!
                    .findCanonicalIngredientByName(item.name);
                canonicalId = canonical?.id;
              }
            }
            if (canonicalId != null && canonicalId.isNotEmpty) {
              availableIngredients[canonicalId] = 
                  (availableIngredients[canonicalId] ?? 0) + item.quantity;
            }
          }
          
          // Calculate cost for missing quantities
          if (_ingredientPriceService != null && _canonicalIngredientService != null) {
            for (final entry in requiredIngredients.entries) {
              final available = availableIngredients[entry.key] ?? 0;
              if (available < entry.value) {
                final missingQuantity = entry.value - available;
                try {
                  // Get price for this ingredient
                  final price = await _ingredientPriceService!.getUserIngredientPrice(entry.key, userId) ??
                      await _ingredientPriceService!.getIngredientPrice(entry.key);
                  if (price != null) {
                    missingIngredientCost += missingQuantity * price.effectivePrice;
                  } else {
                    // Fallback estimate
                    missingIngredientCost += missingQuantity * 2.0;
                  }
                } catch (e) {
                  // Skip if can't get price
                  missingIngredientCost += missingQuantity * 2.0; // Fallback estimate
                }
              }
            }
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



