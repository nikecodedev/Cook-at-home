import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_cost_service.dart';
import '../services/firestore/firestore_service.dart';
import '../core/utils/logger.dart';

/// Service for calculating meal plan costs
class MealPlanCostService {
  final RecipeCostService _recipeCostService;
  final FirestoreService _firestoreService;

  MealPlanCostService({
    required RecipeCostService recipeCostService,
    required FirestoreService firestoreService,
  })  : _recipeCostService = recipeCostService,
        _firestoreService = firestoreService;

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

      // Calculate daily costs
      final Map<String, double> dailyCosts = {};
      for (final entry in mealPlan.dailyRecipes.entries) {
        double dayCost = 0.0;
        for (final recipeId in entry.value) {
          dayCost += recipeCosts[recipeId] ?? 0.0;
        }
        dailyCosts[entry.key] = dayCost;
      }

      // Calculate average cost per day
      final costPerDay = dailyCosts.values.isNotEmpty
          ? dailyCosts.values.reduce((a, b) => a + b) / dailyCosts.length
          : 0.0;

      // Missing ingredient cost would be calculated separately
      // For now, we'll return 0 (this would require pantry comparison)
      final missingIngredientCost = 0.0; // TODO: Calculate based on pantry coverage

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

