import '../models/recipe_model.dart';
import '../core/constants/firebase_constants.dart';

/// Helper class for recipe yield and portion calculations
class RecipeYieldHelper {
  /// Validate yield configuration
  /// Returns error message if invalid, null if valid
  static String? validateYield({
    required double? totalYield,
    required String? yieldUnit,
    required double? portionSize,
  }) {
    // All fields must be provided
    if (totalYield == null) {
      return 'Total yield is required';
    }
    if (yieldUnit == null || yieldUnit.isEmpty) {
      return 'Yield unit is required';
    }
    if (portionSize == null) {
      return 'Portion size is required';
    }

    // Values must be positive
    if (totalYield <= 0) {
      return 'Total yield must be greater than 0';
    }
    if (portionSize <= 0) {
      return 'Portion size must be greater than 0';
    }

    // Portion size cannot exceed total yield
    if (portionSize > totalYield) {
      return 'Portion size cannot be larger than total yield';
    }

    // Validate unit is in allowed list
    if (!YieldUnits.all.contains(yieldUnit)) {
      return 'Invalid yield unit. Must be one of: ${YieldUnits.all.join(", ")}';
    }

    return null; // Valid
  }

  /// Calculate number of servings
  /// Returns null if calculation cannot be performed
  static int? calculateServings({
    required double? totalYield,
    required double? portionSize,
  }) {
    if (totalYield == null || portionSize == null) {
      return null;
    }
    if (totalYield <= 0 || portionSize <= 0) {
      return null;
    }
    if (portionSize > totalYield) {
      return null; // Invalid configuration
    }
    return (totalYield / portionSize).round();
  }

  /// Calculate cost per serving
  /// Returns null if calculation cannot be performed
  static double? calculateCostPerServing({
    required double totalCost,
    required double? totalYield,
    required double? portionSize,
  }) {
    // Method 1: Use yield and portion size
    if (totalYield != null && portionSize != null && totalYield > 0 && portionSize > 0) {
      if (portionSize > totalYield) {
        return null; // Invalid configuration
      }
      // Cost per serving = (totalCost / totalYield) * portionSize
      return (totalCost / totalYield) * portionSize;
    }

    // Method 2: Use number of servings (if available)
    final servings = calculateServings(
      totalYield: totalYield,
      portionSize: portionSize,
    );
    if (servings != null && servings > 0) {
      return totalCost / servings;
    }

    return null;
  }

  /// Calculate cost per serving (alternative method using servings count)
  static double? calculateCostPerServingFromServings({
    required double totalCost,
    required int? numberOfServings,
  }) {
    if (numberOfServings == null || numberOfServings <= 0) {
      return null;
    }
    return totalCost / numberOfServings;
  }

  /// Format yield value with unit
  static String formatYield(double? value, String? unit) {
    if (value == null || unit == null) {
      return 'Not specified';
    }
    final formattedValue = value % 1 == 0 
        ? value.toInt().toString()
        : value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$formattedValue $unit';
  }

  /// Format portion size with unit
  static String formatPortionSize(double? value, String? unit) {
    if (value == null || unit == null) {
      return 'Not specified';
    }
    final formattedValue = value % 1 == 0 
        ? value.toInt().toString()
        : value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$formattedValue $unit';
  }

  /// Get default portion size based on yield unit
  /// Returns a reasonable default portion size for common units
  static double? getDefaultPortionSize(String? yieldUnit, double? totalYield) {
    if (yieldUnit == null || totalYield == null || totalYield <= 0) {
      return null;
    }

    // Default portion sizes based on unit type
    switch (yieldUnit) {
      case YieldUnits.grams:
        return 150.0; // Typical serving size in grams
      case YieldUnits.kilograms:
        return 0.15; // 150 grams = 0.15 kg
      case YieldUnits.liters:
        return 0.25; // Typical serving size in liters (250ml)
      case YieldUnits.milliliters:
        return 250.0; // Typical serving size in milliliters
      case YieldUnits.cups:
        return 1.0; // One cup per serving
      case YieldUnits.pieces:
        return 1.0; // One piece per serving
      default:
        // If total yield is reasonable, suggest 1/4 of total as default
        if (totalYield > 0) {
          return totalYield / 4;
        }
        return null;
    }
  }

  /// Check if recipe has complete yield information
  static bool hasCompleteYield(Recipe recipe) {
    return recipe.yieldValue != null &&
           recipe.yieldUnit != null &&
           recipe.standardPortionSize != null &&
           recipe.yieldValue! > 0 &&
           recipe.standardPortionSize! > 0 &&
           recipe.standardPortionSize! <= recipe.yieldValue!;
  }
}
