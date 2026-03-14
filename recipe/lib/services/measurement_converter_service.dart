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

  /// Normalize any unit string (abbreviations, Spanish, singular, etc.)
  /// to its canonical English plural form used throughout the app.
  /// This ensures consistent unit handling regardless of input format.
  static String normalizeUnit(String unit) {
    final lower = unit.toLowerCase().trim();
    switch (lower) {
      // Weight — grams
      case 'g':
      case 'gr':
      case 'gram':
      case 'gramo':
      case 'gramos':
      case 'grams':
        return 'grams';
      // Weight — kilograms
      case 'kg':
      case 'kilo':
      case 'kilos':
      case 'kilogram':
      case 'kilogramo':
      case 'kilogramos':
      case 'kilograms':
        return 'kilograms';
      // Weight — ounces
      case 'oz':
      case 'ounce':
      case 'onza':
      case 'onzas':
      case 'ounces':
        return 'ounces';
      // Weight — pounds
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'libra':
      case 'libras':
      case 'pounds':
        return 'pounds';
      // Volume — liters
      case 'l':
      case 'lt':
      case 'ltr':
      case 'liter':
      case 'litro':
      case 'litros':
      case 'liters':
        return 'liters';
      // Volume — milliliters
      case 'ml':
      case 'milliliter':
      case 'mililitro':
      case 'mililitros':
      case 'milliliters':
        return 'milliliters';
      // Volume — cups
      case 'cup':
      case 'taza':
      case 'tazas':
      case 'cups':
        return 'cups';
      // Volume — tablespoons
      case 'tbsp':
      case 'tablespoon':
      case 'cucharada':
      case 'cucharadas':
      case 'tablespoons':
        return 'tablespoons';
      // Volume — teaspoons
      case 'tsp':
      case 'teaspoon':
      case 'cucharadita':
      case 'cucharaditas':
      case 'teaspoons':
        return 'teaspoons';
      // Volume — fluid ounces
      case 'fl_oz':
      case 'fluid_ounce':
      case 'onza_liquida':
      case 'onzas_liquidas':
      case 'fluid_ounces':
        return 'fluid_ounces';
      // Volume — pints
      case 'pint':
      case 'pinta':
      case 'pintas':
      case 'pints':
        return 'pints';
      // Volume — quarts
      case 'quart':
      case 'cuarto':
      case 'cuartos':
      case 'quarts':
        return 'quarts';
      // Volume — gallons
      case 'gallon':
      case 'galon':
      case 'galón':
      case 'galones':
      case 'gallons':
        return 'gallons';
      // Count — pieces
      case 'pc':
      case 'pcs':
      case 'piece':
      case 'pieza':
      case 'piezas':
      case 'unidad':
      case 'unidades':
      case 'pieces':
        return 'pieces';
      // Already canonical or unknown — return as-is
      default:
        return lower;
    }
  }

  /// Convert between units
  /// Returns null if conversion is not possible
  static ConversionResult? convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    // Normalize unit names to canonical English forms
    final from = normalizeUnit(fromUnit);
    final to = normalizeUnit(toUnit);

    // Same unit - no conversion needed
    if (from == to) {
      return ConversionResult(value: value, unit: to);
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

  /// Check if unit is a weight unit (expects normalized input)
  static bool _isWeightUnit(String unit) {
    return unit == 'grams' ||
           unit == 'kilograms' ||
           unit == 'ounces' ||
           unit == 'pounds';
  }

  /// Check if unit is a volume unit (expects normalized input)
  static bool _isVolumeUnit(String unit) {
    return unit == 'liters' ||
           unit == 'milliliters' ||
           unit == 'cups' ||
           unit == 'tablespoons' ||
           unit == 'teaspoons' ||
           unit == 'fluid_ounces' ||
           unit == 'pints' ||
           unit == 'quarts' ||
           unit == 'gallons';
  }

  /// Check if a raw unit string is a weight unit (normalizes first)
  static bool isWeightUnit(String unit) {
    return _isWeightUnit(normalizeUnit(unit));
  }

  /// Check if a raw unit string is a volume unit (normalizes first)
  static bool isVolumeUnit(String unit) {
    return _isVolumeUnit(normalizeUnit(unit));
  }

  /// Convert weight units (expects normalized input)
  /// Supports: grams, kilograms, ounces, pounds
  static ConversionResult _convertWeight(double value, String from, String to) {
    // Convert to grams first (base unit)
    double grams;
    String? note;

    if (from == 'kilograms') {
      grams = value * 1000;
    } else if (from == 'ounces') {
      grams = value * 28.3495; // 1 oz = 28.3495 g
    } else if (from == 'pounds') {
      grams = value * 453.592; // 1 lb = 453.592 g
    } else {
      grams = value; // Already in grams
    }

    // Convert from grams to target unit
    double result;

    if (to == 'kilograms') {
      result = grams / 1000;
    } else if (to == 'ounces') {
      result = grams / 28.3495;
      note = '1 onza = 28.35 gramos';
    } else if (to == 'pounds') {
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

  /// Convert volume units (expects normalized input)
  /// Supports: liters, milliliters, cups, tablespoons, teaspoons, fluid ounces, pints, quarts, gallons
  static ConversionResult _convertVolume(double value, String from, String to) {
    // Convert to milliliters first (base unit)
    double milliliters;

    if (from == 'liters') {
      milliliters = value * 1000;
    } else if (from == 'cups') {
      milliliters = value * 236.588; // 1 cup = 236.588 ml (US)
    } else if (from == 'tablespoons') {
      milliliters = value * 14.7868; // 1 tbsp = 14.7868 ml
    } else if (from == 'teaspoons') {
      milliliters = value * 4.92892; // 1 tsp = 4.92892 ml
    } else if (from == 'fluid_ounces') {
      milliliters = value * 29.5735; // 1 fl oz = 29.5735 ml
    } else if (from == 'pints') {
      milliliters = value * 473.176; // 1 pint = 473.176 ml (US)
    } else if (from == 'quarts') {
      milliliters = value * 946.353; // 1 quart = 946.353 ml (US)
    } else if (from == 'gallons') {
      milliliters = value * 3785.41; // 1 gallon = 3785.41 ml (US)
    } else {
      milliliters = value; // Already in milliliters
    }

    // Convert from milliliters to target unit
    double result;
    String? note;

    if (to == 'liters') {
      result = milliliters / 1000;
    } else if (to == 'cups') {
      result = milliliters / 236.588;
      note = '1 taza = 236.6 ml (medida estándar US)';
    } else if (to == 'tablespoons') {
      result = milliliters / 14.7868;
      note = '1 cucharada = 14.8 ml (3 cucharaditas)';
    } else if (to == 'teaspoons') {
      result = milliliters / 4.92892;
      note = '1 cucharadita = 4.9 ml';
    } else if (to == 'fluid_ounces') {
      result = milliliters / 29.5735;
      note = '1 onza líquida = 29.6 ml';
    } else if (to == 'pints') {
      result = milliliters / 473.176;
      note = '1 pinta = 473.2 ml (2 tazas)';
    } else if (to == 'quarts') {
      result = milliliters / 946.353;
      note = '1 cuarto = 946.4 ml (4 tazas)';
    } else if (to == 'gallons') {
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
    final normalized = normalizeUnit(unit);

    if (_isWeightUnit(normalized)) {
      return ['grams', 'kilograms', 'ounces', 'pounds'];
    } else if (_isVolumeUnit(normalized)) {
      return ['liters', 'milliliters', 'cups', 'tablespoons', 'teaspoons', 'fluid_ounces', 'pints', 'quarts', 'gallons'];
    }

    return [];
  }

  /// Check if conversion is possible between two units
  static bool canConvert(String fromUnit, String toUnit) {
    final from = normalizeUnit(fromUnit);
    final to = normalizeUnit(toUnit);

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
