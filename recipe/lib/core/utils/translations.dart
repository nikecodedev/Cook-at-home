import '../constants/firebase_constants.dart';

/// Translation utilities for units and categories
class Translations {
  /// Unit translations: English -> Spanish
  static const Map<String, String> _unitTranslations = {
    'grams': 'gramos',
    'kilograms': 'kilogramos',
    'liters': 'litros',
    'milliliters': 'mililitros',
    'pieces': 'piezas',
    'cups': 'tazas',
    'tablespoons': 'cucharadas',
    'teaspoons': 'cucharaditas',
  };

  /// Pantry category translations: English -> Spanish
  static const Map<String, String> _pantryCategoryTranslations = {
    'Dairy': 'Lácteos',
    'Fruits': 'Frutas',
    'Vegetables': 'Verduras',
    'Meat & Poultry': 'Carne y Aves',
    'Seafood': 'Mariscos',
    'Grains & Bread': 'Granos y Pan',
    'Canned Goods': 'Conservas',
    'Spices & Condiments': 'Especias y Condimentos',
    'Beverages': 'Bebidas',
    'Frozen Foods': 'Alimentos Congelados',
    'Snacks': 'Snacks',
    'Other': 'Otros',
  };

  /// Recipe category translations: English -> Spanish
  static const Map<String, String> _recipeCategoryTranslations = {
    'Breakfast': 'Desayuno',
    'Main Course': 'Plato Principal',
    'Side Dish': 'Acompañamiento',
    'Dessert': 'Postre',
    'Appetizer': 'Aperitivo',
    'Soup & Salad': 'Sopa y Ensalada',
    'Beverages': 'Bebidas',
    'Snacks': 'Snacks',
  };

  /// Translate unit from English to Spanish
  static String translateUnit(String unit) {
    return _unitTranslations[unit.toLowerCase()] ?? unit;
  }

  /// Translate unit from Spanish to English (for storage)
  static String translateUnitToEnglish(String unit) {
    final reversed = Map.fromEntries(
      _unitTranslations.entries.map((e) => MapEntry(e.value, e.key)),
    );
    return reversed[unit.toLowerCase()] ?? unit;
  }

  /// Get all translated units
  static List<String> getTranslatedUnits() {
    return Units.all.map((unit) => translateUnit(unit)).toList();
  }

  /// Translate pantry category from English to Spanish
  static String translatePantryCategory(String category) {
    return _pantryCategoryTranslations[category] ?? category;
  }

  /// Translate pantry category from Spanish to English (for storage)
  static String translatePantryCategoryToEnglish(String category) {
    final reversed = Map.fromEntries(
      _pantryCategoryTranslations.entries.map((e) => MapEntry(e.value, e.key)),
    );
    return reversed[category] ?? category;
  }

  /// Get all translated pantry categories
  static List<String> getTranslatedPantryCategories() {
    return PantryCategories.all.map((cat) => translatePantryCategory(cat)).toList();
  }

  /// Translate recipe category from English to Spanish
  static String translateRecipeCategory(String category) {
    return _recipeCategoryTranslations[category] ?? category;
  }

  /// Translate recipe category from Spanish to English (for storage)
  static String translateRecipeCategoryToEnglish(String category) {
    final reversed = Map.fromEntries(
      _recipeCategoryTranslations.entries.map((e) => MapEntry(e.value, e.key)),
    );
    return reversed[category] ?? category;
  }

  /// Get all translated recipe categories
  static List<String> getTranslatedRecipeCategories() {
    return RecipeCategories.all.map((cat) => translateRecipeCategory(cat)).toList();
  }

  /// Get English unit from Spanish translation (for dropdown selection)
  static String getEnglishUnitFromSpanish(String spanishUnit) {
    return translateUnitToEnglish(spanishUnit);
  }

  /// Get English category from Spanish translation (for dropdown selection)
  static String getEnglishCategoryFromSpanish(String spanishCategory) {
    final pantryResult = translatePantryCategoryToEnglish(spanishCategory);
    if (pantryResult != spanishCategory) return pantryResult;
    
    final recipeResult = translateRecipeCategoryToEnglish(spanishCategory);
    return recipeResult;
  }
}

