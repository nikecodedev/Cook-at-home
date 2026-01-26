import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/canonical_ingredient_service.dart';
import '../services/product_service.dart';
import '../services/ingredient_price_service.dart';
import '../services/recipe_cost_service.dart';
import '../services/pantry_analytics_service.dart';
import '../services/meal_plan_cost_service.dart';
import '../services/refill_alert_service.dart';
import '../services/recipe_sharing_service.dart';
import '../services/firestore/firestore_service.dart';
import '../services/measurement_converter_service.dart';

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
  return PantryAnalyticsService(
    priceService: priceService,
    canonicalService: canonicalService,
  );
});

/// Provider for MealPlanCostService
final mealPlanCostServiceProvider = Provider<MealPlanCostService>((ref) {
  final recipeCostService = ref.watch(recipeCostServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return MealPlanCostService(
    recipeCostService: recipeCostService,
    firestoreService: firestoreService,
  );
});

/// Provider for RefillAlertService
final refillAlertServiceProvider = Provider<RefillAlertService>((ref) {
  return RefillAlertService();
});

/// Provider for RecipeSharingService
final recipeSharingServiceProvider = Provider<RecipeSharingService>((ref) {
  return RecipeSharingService();
});

