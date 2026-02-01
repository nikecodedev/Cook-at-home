import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Delegado de localización de la aplicación
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

  // Cadenas comunes
  String get appName => _localizedValues[locale.languageCode]?['appName'] ?? 'Cocina en tu Casa';
  
  // Cadenas de Fase 2
  String get scanBarcode => _localizedValues[locale.languageCode]?['scanBarcode'] ?? 'Escanear Código de Barras';
  String get contributeProduct => _localizedValues[locale.languageCode]?['contributeProduct'] ?? 'Contribuir Producto';
  String get productName => _localizedValues[locale.languageCode]?['productName'] ?? 'Nombre del Producto';
  String get brand => _localizedValues[locale.languageCode]?['brand'] ?? 'Marca';
  String get category => _localizedValues[locale.languageCode]?['category'] ?? 'Categoría';
  String get suggestedUnit => _localizedValues[locale.languageCode]?['suggestedUnit'] ?? 'Unidad Sugerida';
  String get productPhoto => _localizedValues[locale.languageCode]?['productPhoto'] ?? 'Foto del Producto';
  String get recipeCost => _localizedValues[locale.languageCode]?['recipeCost'] ?? 'Costo de la Receta';
  String get totalCost => _localizedValues[locale.languageCode]?['totalCost'] ?? 'Costo Total';
  String get costPerPortion => _localizedValues[locale.languageCode]?['costPerPortion'] ?? 'Costo por Porción';
  String get costTier => _localizedValues[locale.languageCode]?['costTier'] ?? 'Nivel de Costo';
  String get low => _localizedValues[locale.languageCode]?['low'] ?? 'Bajo';
  String get medium => _localizedValues[locale.languageCode]?['medium'] ?? 'Medio';
  String get high => _localizedValues[locale.languageCode]?['high'] ?? 'Alto';
  String get pantryValue => _localizedValues[locale.languageCode]?['pantryValue'] ?? 'Valor de la Despensa';
  String get totalValue => _localizedValues[locale.languageCode]?['totalValue'] ?? 'Valor Total';
  String get pantryAnalytics => _localizedValues[locale.languageCode]?['pantryAnalytics'] ?? 'Análisis de Despensa';
  String get coveragePercentage => _localizedValues[locale.languageCode]?['coveragePercentage'] ?? 'Cobertura';
  String get coverage => _localizedValues[locale.languageCode]?['coverage'] ?? 'Cobertura';
  String get estimatedMeals => _localizedValues[locale.languageCode]?['estimatedMeals'] ?? 'Comidas Estimadas';
  String get efficiencyScore => _localizedValues[locale.languageCode]?['efficiencyScore'] ?? 'Eficiencia';
  String get missingIngredients => _localizedValues[locale.languageCode]?['missingIngredients'] ?? 'Ingredientes Faltantes';
  String get weeklyMealPlan => _localizedValues[locale.languageCode]?['weeklyMealPlan'] ?? 'Plan de Comidas Semanal';
  String get weeklyCost => _localizedValues[locale.languageCode]?['weeklyCost'] ?? 'Costo Semanal';
  String get costPerDay => _localizedValues[locale.languageCode]?['costPerDay'] ?? 'Costo por Día';
  String get refillAlerts => _localizedValues[locale.languageCode]?['refillAlerts'] ?? 'Alertas de Reabastecimiento';
  String get shareRecipe => _localizedValues[locale.languageCode]?['shareRecipe'] ?? 'Compartir Receta';
  String get recipeYield => _localizedValues[locale.languageCode]?['recipeYield'] ?? 'Rendimiento de la Receta';
  String get yieldValue => _localizedValues[locale.languageCode]?['yieldValue'] ?? 'Valor de Rendimiento';
  String get yieldUnit => _localizedValues[locale.languageCode]?['yieldUnit'] ?? 'Unidad de Rendimiento';
  String get standardPortionSize => _localizedValues[locale.languageCode]?['standardPortionSize'] ?? 'Tamaño de Porción Estándar';
  String get numberOfServings => _localizedValues[locale.languageCode]?['numberOfServings'] ?? 'Número de Porciones';
  String get ingredientPrice => _localizedValues[locale.languageCode]?['ingredientPrice'] ?? 'Precio del Ingrediente';
  String get overridePrice => _localizedValues[locale.languageCode]?['overridePrice'] ?? 'Precio Personalizado';
  String get canonicalIngredient => _localizedValues[locale.languageCode]?['canonicalIngredient'] ?? 'Ingrediente Canónico';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Guardar';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancelar';
  String get required => _localizedValues[locale.languageCode]?['required'] ?? 'Requerido';
  String get optional => _localizedValues[locale.languageCode]?['optional'] ?? 'Opcional';
  String get lowStock => _localizedValues[locale.languageCode]?['lowStock'] ?? 'Stock Bajo';
  String get frequentlyUsed => _localizedValues[locale.languageCode]?['frequentlyUsed'] ?? 'Uso Frecuente';
  String get goodPrice => _localizedValues[locale.languageCode]?['goodPrice'] ?? 'Buen Precio';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Idioma';
  String get languageDescription => _localizedValues[locale.languageCode]?['languageDescription'] ?? 'Selecciona tu idioma preferido para la interfaz de la aplicación';
  String get languageNote => _localizedValues[locale.languageCode]?['languageNote'] ?? 'Nota: El contenido generado por usuarios (recetas, ingredientes) no se traducirá.';
  String get languageChanged => _localizedValues[locale.languageCode]?['languageChanged'] ?? 'Idioma cambiado';
  String get languageChangeError => _localizedValues[locale.languageCode]?['languageChangeError'] ?? 'Error al cambiar el idioma';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
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
      'totalValue': 'Valor Total',
      'pantryAnalytics': 'Análisis de Despensa',
      'coveragePercentage': 'Cobertura',
      'coverage': 'Cobertura',
      'estimatedMeals': 'Comidas Estimadas',
      'efficiencyScore': 'Eficiencia',
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
      'lowStock': 'Stock Bajo',
      'frequentlyUsed': 'Uso Frecuente',
      'goodPrice': 'Buen Precio',
      'language': 'Idioma',
      'languageDescription': 'Selecciona tu idioma preferido para la interfaz de la aplicación',
      'languageNote': 'Nota: El contenido generado por usuarios (recetas, ingredientes) no se traducirá.',
      'languageChanged': 'Idioma cambiado',
      'languageChangeError': 'Error al cambiar el idioma',
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
      'totalValue': 'Valor Total',
      'pantryAnalytics': 'Análisis de Despensa',
      'coveragePercentage': 'Cobertura',
      'coverage': 'Cobertura',
      'estimatedMeals': 'Comidas Estimadas',
      'efficiencyScore': 'Eficiencia',
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
      'lowStock': 'Stock Bajo',
      'frequentlyUsed': 'Uso Frecuente',
      'goodPrice': 'Buen Precio',
      'language': 'Idioma',
      'languageDescription': 'Selecciona tu idioma preferido para la interfaz de la aplicación',
      'languageNote': 'Nota: El contenido generado por usuarios (recetas, ingredientes) no se traducirá.',
      'languageChanged': 'Idioma cambiado',
      'languageChangeError': 'Error al cambiar el idioma',
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



