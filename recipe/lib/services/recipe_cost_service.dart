import '../models/recipe_model.dart';
import '../models/ingredient_price_model.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
import '../core/utils/logger.dart';
import '../core/constants/firebase_constants.dart';
import '../core/config/cost_tier_config.dart';
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
  /// Always fetches fresh prices (no caching) to ensure accuracy
  /// Recalculates dynamically when recipe or prices change
  Future<RecipeCostCalculation> calculateRecipeCost(
    Recipe recipe,
    String? userId,
  ) async {
    try {
      double totalCost = 0.0;
      final Map<String, double> ingredientCosts = {};

      // Early return if no ingredients
      if (recipe.ingredients.isEmpty) {
        return RecipeCostCalculation(
          totalCost: 0.0,
          costPerPortion: null,
          costTier: CostTiers.low,
          ingredientCosts: {},
          numberOfServings: recipe.numberOfServings,
        );
      }

      // Resolve canonical ingredient IDs (with name fallback for backward compatibility)
      final List<String> resolvedIds = [];
      final Map<String, String> ingredientToCanonicalId = {}; // ingredient name -> canonical ID
      
      for (final ingredient in recipe.ingredients) {
        String? canonicalId = ingredient.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          // Try to find canonical ingredient by name (backward compatibility)
          final canonical = await _canonicalService.findCanonicalIngredientByName(ingredient.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId != null && canonicalId.isNotEmpty) {
          resolvedIds.add(canonicalId);
          ingredientToCanonicalId[ingredient.name] = canonicalId;
        }
      }

      // Early return if no canonical ingredients found
      if (resolvedIds.isEmpty) {
        return RecipeCostCalculation(
          totalCost: 0.0,
          costPerPortion: null,
          costTier: CostTiers.low,
          ingredientCosts: {},
          numberOfServings: recipe.numberOfServings,
        );
      }

      // Get prices for all ingredients (always fresh, no caching)
      // Batch get for performance (handles Firestore 'in' query limit of 10)
      final prices = userId != null
          ? await _getUserPrices(resolvedIds, userId)
          : await _priceService.getIngredientPrices(resolvedIds);

      // Calculate cost for each ingredient
      for (final ingredient in recipe.ingredients) {
        // Get canonical ID from map (already resolved above)
        final canonicalId = ingredient.canonicalIngredientId ?? 
                           ingredientToCanonicalId[ingredient.name];
        
        if (canonicalId == null || canonicalId.isEmpty) {
          // No canonical ingredient found - skip this ingredient
          continue;
        }

        final price = prices[canonicalId];
        if (price == null) {
          // No price available for this ingredient - skip
          continue;
        }

        // Convert ingredient quantity to price unit and calculate cost
        double cost = 0.0;
        try {
          double convertedQuantity = ingredient.quantity;

          // Normalize both units before comparing to handle abbreviations,
          // Spanish variants, and case differences (e.g., 'ml' vs 'milliliters')
          final normalizedIngredientUnit = MeasurementConverterService.normalizeUnit(ingredient.unit);
          final normalizedPriceUnit = MeasurementConverterService.normalizeUnit(price.priceUnit);

          if (normalizedIngredientUnit != normalizedPriceUnit) {
            // Need to convert units (converter also normalizes internally)
            final conversion = MeasurementConverterService.convert(
              value: ingredient.quantity,
              fromUnit: ingredient.unit,
              toUnit: price.priceUnit,
            );
            if (conversion != null) {
              convertedQuantity = conversion.value;
            } else {
              // Units are incompatible (e.g., volume ↔ weight, pieces ↔ weight)
              // Skip this ingredient rather than calculate with wrong units
              Logger.warning(
                'Cannot convert "${ingredient.unit}" to "${price.priceUnit}" for ${ingredient.name} — skipping cost',
                'RecipeCostService',
              );
              continue;
            }
          }

          // Use the price model's calculateCost which handles all pricing types
          // (perUnit, perPackage, perWeight)
          cost = price.calculateCost(convertedQuantity);

          totalCost += cost;
          ingredientCosts[ingredient.name] = cost;
        } catch (e) {
          Logger.warning('Failed to calculate cost for ingredient: ${ingredient.name}', 'RecipeCostService');
        }
      }

      // Calculate cost per serving/portion
      double? costPerPortion;
      
      // Method 1: Use yield and portion size (most accurate)
      if (recipe.yieldValue != null && 
          recipe.standardPortionSize != null && 
          recipe.standardPortionSize! > 0 &&
          recipe.yieldValue! > 0) {
        // Cost per serving = (totalCost / totalYield) * portionSize
        costPerPortion = (totalCost / recipe.yieldValue!) * recipe.standardPortionSize!;
      } 
      // Method 2: Use calculated number of servings (fallback)
      else if (recipe.numberOfServings != null && recipe.numberOfServings! > 0) {
        costPerPortion = totalCost / recipe.numberOfServings!;
      }
      // If no yield information, cost per portion cannot be calculated

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
  /// Uses configurable thresholds from CostTierConfig
  String _determineCostTier(double costPerPortion) {
    return CostTierConfig.determineTier(costPerPortion);
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

