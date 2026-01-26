import '../models/pantry_item_model.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_price_model.dart';
import '../services/ingredient_price_service.dart';
import '../services/canonical_ingredient_service.dart';
import '../core/utils/logger.dart';
import '../services/measurement_converter_service.dart' show MeasurementConverterService;

/// Service for calculating pantry value and coverage metrics
class PantryAnalyticsService {
  final IngredientPriceService _priceService;
  final CanonicalIngredientService _canonicalService;

  PantryAnalyticsService({
    required IngredientPriceService priceService,
    required CanonicalIngredientService canonicalService,
  })  : _priceService = priceService,
        _canonicalService = canonicalService;

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

        // Convert item quantity to price unit
        double value = 0.0;
        try {
          if (item.unit == price.priceUnit) {
            value = item.quantity * price.effectivePrice;
          } else {
            final conversion = MeasurementConverterService.convert(
              value: item.quantity,
              fromUnit: item.unit,
              toUnit: price.priceUnit,
            );
            if (conversion != null) {
              value = conversion.value * price.effectivePrice;
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
      final Map<String, double> requiredIngredients = {}; // canonicalId -> total quantity needed
      final Map<String, String> ingredientNames = {}; // canonicalId -> display name

      for (final recipe in plannedRecipes) {
        for (final ingredient in recipe.ingredients) {
          String? canonicalId = ingredient.canonicalIngredientId;
          
          if (canonicalId == null || canonicalId.isEmpty) {
            final canonical = await _canonicalService.findCanonicalIngredientByName(ingredient.name);
            canonicalId = canonical?.id;
          }

          if (canonicalId != null && canonicalId.isNotEmpty) {
            final key = canonicalId;
            requiredIngredients[key] = (requiredIngredients[key] ?? 0) + ingredient.quantity;
            ingredientNames[key] = ingredient.name;
          }
        }
      }

      // Check pantry availability
      final Map<String, double> availableIngredients = {}; // canonicalId -> available quantity
      final List<String> missingIngredients = [];

      for (final item in pantryItems) {
        String? canonicalId = item.canonicalIngredientId;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          final canonical = await _canonicalService.findCanonicalIngredientByName(item.name);
          canonicalId = canonical?.id;
        }

        if (canonicalId != null && canonicalId.isNotEmpty && requiredIngredients.containsKey(canonicalId)) {
          availableIngredients[canonicalId] = (availableIngredients[canonicalId] ?? 0) + item.quantity;
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

