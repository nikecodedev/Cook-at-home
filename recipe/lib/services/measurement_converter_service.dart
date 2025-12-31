/// Conversion result model
class ConversionResult {
  final double value;
  final String unit;
  final String? note;

  ConversionResult({
    required this.value,
    required this.unit,
    this.note,
  });

  String get formattedValue {
    // Format to show reasonable precision
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    } else if (value >= 100) {
      return value.toStringAsFixed(1);
    } else if (value >= 10) {
      return value.toStringAsFixed(2);
    } else if (value >= 1) {
      return value.toStringAsFixed(2);
    } else if (value >= 0.01) {
      return value.toStringAsFixed(3);
    } else {
      return value.toStringAsFixed(4);
    }
  }
}

/// Service for converting between different measurement units
/// Handles conversions for common cooking measurements
class MeasurementConverterService {
  /// Convert between units
  /// Returns null if conversion is not possible
  static ConversionResult? convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    // Normalize unit names
    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();

    // Same unit - no conversion needed
    if (from == to) {
      return ConversionResult(value: value, unit: toUnit);
    }

    // Weight conversions
    if (_isWeightUnit(from) && _isWeightUnit(to)) {
      return _convertWeight(value, from, to);
    }

    // Volume conversions
    if (_isVolumeUnit(from) && _isVolumeUnit(to)) {
      return _convertVolume(value, from, to);
    }

    // Cannot convert between incompatible units
    return null;
  }

  /// Check if unit is a weight unit
  static bool _isWeightUnit(String unit) {
    final normalized = unit.toLowerCase().trim();
    return normalized == 'grams' ||
           normalized == 'kilograms' ||
           normalized == 'ounces' ||
           normalized == 'pounds' ||
           normalized == 'gramos' ||
           normalized == 'kilogramos' ||
           normalized == 'onzas' ||
           normalized == 'libras';
  }

  /// Check if unit is a volume unit
  static bool _isVolumeUnit(String unit) {
    final normalized = unit.toLowerCase().trim();
    return normalized == 'liters' ||
           normalized == 'milliliters' ||
           normalized == 'cups' ||
           normalized == 'tablespoons' ||
           normalized == 'teaspoons' ||
           normalized == 'fluid_ounces' ||
           normalized == 'pints' ||
           normalized == 'quarts' ||
           normalized == 'gallons' ||
           normalized == 'litros' ||
           normalized == 'mililitros' ||
           normalized == 'tazas' ||
           normalized == 'cucharadas' ||
           normalized == 'cucharaditas' ||
           normalized == 'onzas_liquidas' ||
           normalized == 'pintas' ||
           normalized == 'cuartos' ||
           normalized == 'galones';
  }

  /// Convert weight units
  /// Supports: grams, kilograms, ounces, pounds
  static ConversionResult _convertWeight(double value, String from, String to) {
    // Convert to grams first (base unit)
    double grams;
    String? note;

    if (from == 'kilograms' || from == 'kilogramos') {
      grams = value * 1000;
    } else if (from == 'ounces' || from == 'onzas') {
      grams = value * 28.3495; // 1 oz = 28.3495 g
    } else if (from == 'pounds' || from == 'libras') {
      grams = value * 453.592; // 1 lb = 453.592 g
    } else {
      grams = value; // Already in grams
    }

    // Convert from grams to target unit
    double result;

    if (to == 'kilograms' || to == 'kilogramos') {
      result = grams / 1000;
    } else if (to == 'ounces' || to == 'onzas') {
      result = grams / 28.3495;
      note = '1 onza = 28.35 gramos';
    } else if (to == 'pounds' || to == 'libras') {
      result = grams / 453.592;
      note = '1 libra = 453.6 gramos (16 onzas)';
    } else {
      result = grams; // Keep in grams
    }

    return ConversionResult(
      value: result,
      unit: to,
      note: note,
    );
  }

  /// Convert volume units
  /// Supports: liters, milliliters, cups, tablespoons, teaspoons, fluid ounces, pints, quarts, gallons
  static ConversionResult _convertVolume(double value, String from, String to) {
    // Convert to milliliters first (base unit)
    double milliliters;

    if (from == 'liters' || from == 'litros') {
      milliliters = value * 1000;
    } else if (from == 'cups' || from == 'tazas') {
      milliliters = value * 236.588; // 1 cup = 236.588 ml (US)
    } else if (from == 'tablespoons' || from == 'cucharadas') {
      milliliters = value * 14.7868; // 1 tbsp = 14.7868 ml
    } else if (from == 'teaspoons' || from == 'cucharaditas') {
      milliliters = value * 4.92892; // 1 tsp = 4.92892 ml
    } else if (from == 'fluid_ounces' || from == 'onzas_liquidas') {
      milliliters = value * 29.5735; // 1 fl oz = 29.5735 ml
    } else if (from == 'pints' || from == 'pintas') {
      milliliters = value * 473.176; // 1 pint = 473.176 ml (US)
    } else if (from == 'quarts' || from == 'cuartos') {
      milliliters = value * 946.353; // 1 quart = 946.353 ml (US)
    } else if (from == 'gallons' || from == 'galones') {
      milliliters = value * 3785.41; // 1 gallon = 3785.41 ml (US)
    } else {
      milliliters = value; // Already in milliliters
    }

    // Convert from milliliters to target unit
    double result;
    String? note;

    if (to == 'liters' || to == 'litros') {
      result = milliliters / 1000;
    } else if (to == 'cups' || to == 'tazas') {
      result = milliliters / 236.588;
      note = '1 taza = 236.6 ml (medida estándar US)';
    } else if (to == 'tablespoons' || to == 'cucharadas') {
      result = milliliters / 14.7868;
      note = '1 cucharada = 14.8 ml (3 cucharaditas)';
    } else if (to == 'teaspoons' || to == 'cucharaditas') {
      result = milliliters / 4.92892;
      note = '1 cucharadita = 4.9 ml';
    } else if (to == 'fluid_ounces' || to == 'onzas_liquidas') {
      result = milliliters / 29.5735;
      note = '1 onza líquida = 29.6 ml';
    } else if (to == 'pints' || to == 'pintas') {
      result = milliliters / 473.176;
      note = '1 pinta = 473.2 ml (2 tazas)';
    } else if (to == 'quarts' || to == 'cuartos') {
      result = milliliters / 946.353;
      note = '1 cuarto = 946.4 ml (4 tazas)';
    } else if (to == 'gallons' || to == 'galones') {
      result = milliliters / 3785.41;
      note = '1 galón = 3.785 litros (16 tazas)';
    } else {
      result = milliliters; // Keep in milliliters
    }

    return ConversionResult(
      value: result,
      unit: to,
      note: note,
    );
  }

  /// Get all compatible units for a given unit
  static List<String> getCompatibleUnits(String unit) {
    final normalized = unit.toLowerCase().trim();

    if (_isWeightUnit(normalized)) {
      return ['grams', 'kilograms', 'ounces', 'pounds'];
    } else if (_isVolumeUnit(normalized)) {
      return ['liters', 'milliliters', 'cups', 'tablespoons', 'teaspoons', 'fluid_ounces', 'pints', 'quarts', 'gallons'];
    }

    return [];
  }

  /// Check if conversion is possible between two units
  static bool canConvert(String fromUnit, String toUnit) {
    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();

    if (from == to) return true;

    return (_isWeightUnit(from) && _isWeightUnit(to)) ||
           (_isVolumeUnit(from) && _isVolumeUnit(to));
  }

  /// Get common cooking equivalents as a helpful reference
  static Map<String, String> getCommonEquivalents() {
    return {
      '1 taza': '16 cucharadas = 48 cucharaditas',
      '1 cucharada': '3 cucharaditas',
      '1 libra': '16 onzas = 453.6 gramos',
      '1 kilogramo': '2.2 libras = 35.3 onzas',
      '1 litro': '4.2 tazas = 33.8 onzas líquidas',
      '1 galón': '4 cuartos = 8 pintas = 16 tazas',
    };
  }
}
