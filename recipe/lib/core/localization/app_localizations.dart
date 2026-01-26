import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// App localization delegate
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  // Common strings
  String get appName => _localizedValues[locale.languageCode]?['appName'] ?? 'Cocina en tu Casa';
  
  // Phase 2 strings
  String get scanBarcode => _localizedValues[locale.languageCode]?['scanBarcode'] ?? 'Scan Barcode';
  String get contributeProduct => _localizedValues[locale.languageCode]?['contributeProduct'] ?? 'Contribute Product';
  String get productName => _localizedValues[locale.languageCode]?['productName'] ?? 'Product Name';
  String get brand => _localizedValues[locale.languageCode]?['brand'] ?? 'Brand';
  String get category => _localizedValues[locale.languageCode]?['category'] ?? 'Category';
  String get suggestedUnit => _localizedValues[locale.languageCode]?['suggestedUnit'] ?? 'Suggested Unit';
  String get productPhoto => _localizedValues[locale.languageCode]?['productPhoto'] ?? 'Product Photo';
  String get recipeCost => _localizedValues[locale.languageCode]?['recipeCost'] ?? 'Recipe Cost';
  String get totalCost => _localizedValues[locale.languageCode]?['totalCost'] ?? 'Total Cost';
  String get costPerPortion => _localizedValues[locale.languageCode]?['costPerPortion'] ?? 'Cost per Portion';
  String get costTier => _localizedValues[locale.languageCode]?['costTier'] ?? 'Cost Tier';
  String get low => _localizedValues[locale.languageCode]?['low'] ?? 'Low';
  String get medium => _localizedValues[locale.languageCode]?['medium'] ?? 'Medium';
  String get high => _localizedValues[locale.languageCode]?['high'] ?? 'High';
  String get pantryValue => _localizedValues[locale.languageCode]?['pantryValue'] ?? 'Pantry Value';
  String get coveragePercentage => _localizedValues[locale.languageCode]?['coveragePercentage'] ?? 'Coverage';
  String get estimatedMeals => _localizedValues[locale.languageCode]?['estimatedMeals'] ?? 'Estimated Meals';
  String get missingIngredients => _localizedValues[locale.languageCode]?['missingIngredients'] ?? 'Missing Ingredients';
  String get weeklyMealPlan => _localizedValues[locale.languageCode]?['weeklyMealPlan'] ?? 'Weekly Meal Plan';
  String get weeklyCost => _localizedValues[locale.languageCode]?['weeklyCost'] ?? 'Weekly Cost';
  String get costPerDay => _localizedValues[locale.languageCode]?['costPerDay'] ?? 'Cost per Day';
  String get refillAlerts => _localizedValues[locale.languageCode]?['refillAlerts'] ?? 'Refill Alerts';
  String get shareRecipe => _localizedValues[locale.languageCode]?['shareRecipe'] ?? 'Share Recipe';
  String get recipeYield => _localizedValues[locale.languageCode]?['recipeYield'] ?? 'Recipe Yield';
  String get yieldValue => _localizedValues[locale.languageCode]?['yieldValue'] ?? 'Yield Value';
  String get yieldUnit => _localizedValues[locale.languageCode]?['yieldUnit'] ?? 'Yield Unit';
  String get standardPortionSize => _localizedValues[locale.languageCode]?['standardPortionSize'] ?? 'Standard Portion Size';
  String get numberOfServings => _localizedValues[locale.languageCode]?['numberOfServings'] ?? 'Number of Servings';
  String get ingredientPrice => _localizedValues[locale.languageCode]?['ingredientPrice'] ?? 'Ingredient Price';
  String get overridePrice => _localizedValues[locale.languageCode]?['overridePrice'] ?? 'Override Price';
  String get canonicalIngredient => _localizedValues[locale.languageCode]?['canonicalIngredient'] ?? 'Canonical Ingredient';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get required => _localizedValues[locale.languageCode]?['required'] ?? 'Required';
  String get optional => _localizedValues[locale.languageCode]?['optional'] ?? 'Optional';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Cocina en tu Casa',
      'scanBarcode': 'Scan Barcode',
      'contributeProduct': 'Contribute Product',
      'productName': 'Product Name',
      'brand': 'Brand',
      'category': 'Category',
      'suggestedUnit': 'Suggested Unit',
      'productPhoto': 'Product Photo',
      'recipeCost': 'Recipe Cost',
      'totalCost': 'Total Cost',
      'costPerPortion': 'Cost per Portion',
      'costTier': 'Cost Tier',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'pantryValue': 'Pantry Value',
      'coveragePercentage': 'Coverage',
      'estimatedMeals': 'Estimated Meals',
      'missingIngredients': 'Missing Ingredients',
      'weeklyMealPlan': 'Weekly Meal Plan',
      'weeklyCost': 'Weekly Cost',
      'costPerDay': 'Cost per Day',
      'refillAlerts': 'Refill Alerts',
      'shareRecipe': 'Share Recipe',
      'recipeYield': 'Recipe Yield',
      'yieldValue': 'Yield Value',
      'yieldUnit': 'Yield Unit',
      'standardPortionSize': 'Standard Portion Size',
      'numberOfServings': 'Number of Servings',
      'ingredientPrice': 'Ingredient Price',
      'overridePrice': 'Override Price',
      'canonicalIngredient': 'Canonical Ingredient',
      'save': 'Save',
      'cancel': 'Cancel',
      'required': 'Required',
      'optional': 'Optional',
    },
    'es': {
      'appName': 'Cocina en tu Casa',
      'scanBarcode': 'Escanear Código de Barras',
      'contributeProduct': 'Contribuir Producto',
      'productName': 'Nombre del Producto',
      'brand': 'Marca',
      'category': 'Categoría',
      'suggestedUnit': 'Unidad Sugerida',
      'productPhoto': 'Foto del Producto',
      'recipeCost': 'Costo de la Receta',
      'totalCost': 'Costo Total',
      'costPerPortion': 'Costo por Porción',
      'costTier': 'Nivel de Costo',
      'low': 'Bajo',
      'medium': 'Medio',
      'high': 'Alto',
      'pantryValue': 'Valor de la Despensa',
      'coveragePercentage': 'Cobertura',
      'estimatedMeals': 'Comidas Estimadas',
      'missingIngredients': 'Ingredientes Faltantes',
      'weeklyMealPlan': 'Plan de Comidas Semanal',
      'weeklyCost': 'Costo Semanal',
      'costPerDay': 'Costo por Día',
      'refillAlerts': 'Alertas de Reabastecimiento',
      'shareRecipe': 'Compartir Receta',
      'recipeYield': 'Rendimiento de la Receta',
      'yieldValue': 'Valor de Rendimiento',
      'yieldUnit': 'Unidad de Rendimiento',
      'standardPortionSize': 'Tamaño de Porción Estándar',
      'numberOfServings': 'Número de Porciones',
      'ingredientPrice': 'Precio del Ingrediente',
      'overridePrice': 'Precio Personalizado',
      'canonicalIngredient': 'Ingrediente Canónico',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'required': 'Requerido',
      'optional': 'Opcional',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

