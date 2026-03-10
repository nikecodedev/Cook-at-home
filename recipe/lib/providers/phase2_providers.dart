import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/canonical_ingredient_service.dart';
import '../services/product_service.dart';
import '../services/ingredient_price_service.dart';
import '../services/recipe_cost_service.dart';
import '../services/pantry_analytics_service.dart';
import '../services/meal_plan_cost_service.dart';
import '../services/meal_plan_service.dart';
import '../services/refill_alert_service.dart';
import '../services/recipe_sharing_service.dart';
import '../services/firestore/firestore_service.dart';
import '../services/measurement_converter_service.dart';
import '../models/recipe_model.dart';
import 'profile_provider.dart';

/// Provider for CanonicalIngredientService
final canonicalIngredientServiceProvider = Provider<CanonicalIngredientService>((ref) {
  return CanonicalIngredientService();
});

/// Provider for ProductService
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

/// Provider for IngredientPriceService
final ingredientPriceServiceProvider = Provider<IngredientPriceService>((ref) {
  return IngredientPriceService();
});

/// Provider for RecipeCostService
final recipeCostServiceProvider = Provider<RecipeCostService>((ref) {
  final priceService = ref.watch(ingredientPriceServiceProvider);
  final canonicalService = ref.watch(canonicalIngredientServiceProvider);
  return RecipeCostService(
    priceService: priceService,
    canonicalService: canonicalService,
  );
});

/// Provider for PantryAnalyticsService
final pantryAnalyticsServiceProvider = Provider<PantryAnalyticsService>((ref) {
  final priceService = ref.watch(ingredientPriceServiceProvider);
  final canonicalService = ref.watch(canonicalIngredientServiceProvider);
  final mealPlanService = ref.watch(mealPlanServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PantryAnalyticsService(
    priceService: priceService,
    canonicalService: canonicalService,
    mealPlanService: mealPlanService,
    firestoreService: firestoreService,
  );
});

/// Provider for MealPlanCostService
final mealPlanCostServiceProvider = Provider<MealPlanCostService>((ref) {
  final recipeCostService = ref.watch(recipeCostServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final pantryAnalyticsService = ref.watch(pantryAnalyticsServiceProvider);
  final ingredientPriceService = ref.watch(ingredientPriceServiceProvider);
  final canonicalIngredientService = ref.watch(canonicalIngredientServiceProvider);
  return MealPlanCostService(
    recipeCostService: recipeCostService,
    firestoreService: firestoreService,
    pantryAnalyticsService: pantryAnalyticsService,
    ingredientPriceService: ingredientPriceService,
    canonicalIngredientService: canonicalIngredientService,
  );
});

/// Provider for RefillAlertService
final refillAlertServiceProvider = Provider<RefillAlertService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final ingredientPriceService = ref.watch(ingredientPriceServiceProvider);
  final mealPlanService = ref.watch(mealPlanServiceProvider);
  return RefillAlertService(
    firestoreService: firestoreService,
    ingredientPriceService: ingredientPriceService,
    mealPlanService: mealPlanService,
  );
});

/// Provider for RecipeSharingService
final recipeSharingServiceProvider = Provider<RecipeSharingService>((ref) {
  return RecipeSharingService();
});

/// Provider for MealPlanService
final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  return MealPlanService();
});

/// Counter that increments when ingredient prices are saved,
/// causing recipeCostProvider to re-fetch fresh data.
/// Call ref.read(priceVersionProvider.notifier).state++ after saving a price.
final priceVersionProvider = StateProvider<int>((ref) => 0);

/// Provider for recipe cost calculation (reactive)
/// Recalculates when recipe, prices change, or priceVersion bumps
final recipeCostProvider = FutureProvider.family<RecipeCostCalculation, RecipeCostParams>((ref, params) async {
  // Watch the price version so we recalculate when prices are saved
  ref.watch(priceVersionProvider);
  final costService = ref.watch(recipeCostServiceProvider);
  return await costService.calculateRecipeCost(
    params.recipe,
    params.userId,
  );
});

/// Parameters for recipe cost calculation
class RecipeCostParams {
  final Recipe recipe;
  final String? userId;

  RecipeCostParams({
    required this.recipe,
    this.userId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeCostParams &&
          runtimeType == other.runtimeType &&
          recipe.id == other.recipe.id &&
          recipe.updatedAt == other.recipe.updatedAt &&
          userId == other.userId;

  @override
  int get hashCode => recipe.id.hashCode ^ recipe.updatedAt.hashCode ^ (userId?.hashCode ?? 0);
}

