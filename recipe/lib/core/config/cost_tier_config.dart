import '../constants/firebase_constants.dart';

/// Configuration for cost tier thresholds
/// Can be customized based on market, currency, or user preferences
class CostTierConfig {
  /// Low cost threshold (default: $2.00)
  /// Recipes below this cost per portion are considered "low"
  static const double defaultLowThreshold = 2.0;

  /// Medium cost threshold (default: $5.00)
  /// Recipes between low and medium thresholds are considered "medium"
  /// Recipes above medium threshold are considered "high"
  static const double defaultMediumThreshold = 5.0;

  /// Get cost tier thresholds
  /// Can be overridden for different markets/currencies
  static Map<String, double> getThresholds({
    double? lowThreshold,
    double? mediumThreshold,
  }) {
    return {
      'low': lowThreshold ?? defaultLowThreshold,
      'medium': mediumThreshold ?? defaultMediumThreshold,
      'high': double.infinity, // No upper limit
    };
  }

  /// Determine cost tier with custom thresholds
  static String determineTier(
    double costPerPortion, {
    double? lowThreshold,
    double? mediumThreshold,
  }) {
    final low = lowThreshold ?? defaultLowThreshold;
    final medium = mediumThreshold ?? defaultMediumThreshold;

    if (costPerPortion < low) {
      return CostTiers.low;
    } else if (costPerPortion < medium) {
      return CostTiers.medium;
    } else {
      return CostTiers.high;
    }
  }
}
