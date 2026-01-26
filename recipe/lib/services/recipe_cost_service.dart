import '../models/recipe_model.dart';
import '../models/ingredient_price_model.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
import '../core/utils/logger.dart';
import '../core/constants/firebase_constants.dart';
import '../services/measurement_converter_service.dart' show MeasurementConverterService;

/// Service for calculating recipe costs
class RecipeCostService {
  final IngredientPriceService _priceService;
  final CanonicalIngredientService _canonicalService;

  RecipeCostService({
    required IngredientPriceService priceService,
    required CanonicalIngredientService canonicalService,
  })  : _priceService = priceService,
        _canonicalService = canonicalService;

  /// Calculate total cost for a recipe
  Future<RecipeCostCalculation> calculateRecipeCost(
    Recipe recipe,
    String? userId,
  ) async {
    try {
      double totalCost = 0.0;
      final Map<String, double> ingredientCosts = {};

      // Get all canonical ingredient IDs from recipe ingredients
      final List<String?> canonicalIds = recipe.ingredients
          .map((ing) => ing.canonicalIngredientId)
          .where((id) => id != null && id.isNotEmpty)
          .toList();

      // If no canonical IDs, try to find them by name
      final List<String> resolvedIds = [];
      for (final ingredient in recipe.ingredients) {
        String? canonicalId = ingredient.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          // Try to find canonical ingredient by name
          final canonical = await _canonicalService.findCanonicalIngredientByName(ingredient.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId != null && canonicalId.isNotEmpty) {
          resolvedIds.add(canonicalId);
        }
      }

      // Get prices for all ingredients
      final prices = userId != null
          ? await _getUserPrices(resolvedIds, userId)
          : await _priceService.getIngredientPrices(resolvedIds);

      // Calculate cost for each ingredient
      for (final ingredient in recipe.ingredients) {
        String? canonicalId = ingredient.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          final canonical = await _canonicalService.findCanonicalIngredientByName(ingredient.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId == null) {
          // No price available for this ingredient
          continue;
        }

        final price = prices[canonicalId];
        if (price == null) {
          continue;
        }

        // Convert ingredient quantity to price unit
        double cost = 0.0;
        try {
          if (ingredient.unit == price.priceUnit) {
            // Same unit, direct calculation
            cost = ingredient.quantity * price.effectivePrice;
          } else {
            // Need to convert
            final conversion = MeasurementConverterService.convert(
              value: ingredient.quantity,
              fromUnit: ingredient.unit,
              toUnit: price.priceUnit,
            );
            if (conversion != null) {
              cost = conversion.value * price.effectivePrice;
            }
          }

          totalCost += cost;
          ingredientCosts[ingredient.name] = cost;
        } catch (e) {
          Logger.warning('Failed to calculate cost for ingredient: ${ingredient.name}', 'RecipeCostService');
        }
      }

      // Calculate cost per portion
      double? costPerPortion;
      if (recipe.yieldValue != null && recipe.standardPortionSize != null && recipe.standardPortionSize! > 0) {
        costPerPortion = (totalCost / recipe.yieldValue!) * recipe.standardPortionSize!;
      } else if (recipe.numberOfServings != null && recipe.numberOfServings! > 0) {
        costPerPortion = totalCost / recipe.numberOfServings!;
      }

      // Determine cost tier
      final costTier = _determineCostTier(costPerPortion ?? totalCost);

      return RecipeCostCalculation(
        totalCost: totalCost,
        costPerPortion: costPerPortion,
        costTier: costTier,
        ingredientCosts: ingredientCosts,
        numberOfServings: recipe.numberOfServings,
      );
    } catch (e) {
      Logger.error('Failed to calculate recipe cost', e, null, 'RecipeCostService');
      return RecipeCostCalculation(
        totalCost: 0.0,
        costPerPortion: null,
        costTier: CostTiers.low,
        ingredientCosts: {},
        numberOfServings: null,
      );
    }
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

  /// Determine cost tier based on cost per portion
  String _determineCostTier(double costPerPortion) {
    // Adjust thresholds based on your market/currency
    if (costPerPortion < 2.0) {
      return CostTiers.low;
    } else if (costPerPortion < 5.0) {
      return CostTiers.medium;
    } else {
      return CostTiers.high;
    }
  }
}

/// Result of recipe cost calculation
class RecipeCostCalculation {
  final double totalCost;
  final double? costPerPortion;
  final String costTier; // low, medium, high
  final Map<String, double> ingredientCosts; // Cost per ingredient
  final int? numberOfServings;

  RecipeCostCalculation({
    required this.totalCost,
    this.costPerPortion,
    required this.costTier,
    required this.ingredientCosts,
    this.numberOfServings,
  });
}

