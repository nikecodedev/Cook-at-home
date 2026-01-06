import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import '../core/utils/logger.dart';

/// Model for recipe recommendation with coverage info
class RecipeRecommendation {
  final Recipe recipe;
  final double coveragePercentage; // 0.0 to 1.0
  final List<RecipeIngredient> availableIngredients;
  final List<RecipeIngredient> missingIngredients;

  RecipeRecommendation({
    required this.recipe,
    required this.coveragePercentage,
    required this.availableIngredients,
    required this.missingIngredients,
  });

  /// Get coverage percentage as integer (0-100)
  int get coveragePercent => (coveragePercentage * 100).round();
}

/// Service for recommending recipes based on pantry items
class RecipeRecommendationService {
  /// Common ingredient synonyms and variations (English and Spanish)
  /// Expanded with more variations for better matching
  static final Map<String, List<String>> _ingredientSynonyms = {
    // POULTRY - English & Spanish
    'chicken': [
      'chicken breast', 'chicken breasts', 'chicken thigh', 'chicken thighs',
      'chicken wing', 'chicken wings', 'chicken drumstick', 'chicken drumsticks',
      'whole chicken', 'chicken pieces', 'chicken meat', 'boneless chicken',
      'skinless chicken', 'chicken fillet', 'chicken fillets',
      // Spanish
      'pollo', 'pechuga de pollo', 'pechugas de pollo', 'muslo de pollo', 'muslos de pollo',
      'ala de pollo', 'alas de pollo', 'pollo entero', 'pierna de pollo', 'piernas de pollo',
    ],
    'pollo': [
      'chicken', 'chicken breast', 'chicken breasts', 'chicken thigh', 'chicken thighs',
      'pechuga de pollo', 'pechugas de pollo', 'muslo de pollo', 'muslos de pollo',
      'ala de pollo', 'alas de pollo', 'pollo entero', 'pierna de pollo',
    ],

    // VEGETABLES - English & Spanish
    'tomato': [
      'tomatoes', 'cherry tomato', 'cherry tomatoes', 'roma tomato', 'roma tomatoes',
      'plum tomato', 'plum tomatoes', 'beefsteak tomato', 'grape tomato',
      // Spanish
      'tomate', 'tomates', 'tomate cherry', 'tomates cherry', 'jitomate', 'jitomates',
    ],
    'tomate': [
      'tomato', 'tomatoes', 'tomates', 'jitomate', 'jitomates', 'tomate cherry',
    ],
    'onion': [
      'onions', 'yellow onion', 'yellow onions', 'white onion', 'white onions',
      'red onion', 'red onions', 'sweet onion', 'sweet onions', 'green onion',
      'green onions', 'scallion', 'scallions',
      // Spanish
      'cebolla', 'cebollas', 'cebolla blanca', 'cebolla morada', 'cebolla roja',
      'cebolleta', 'cebolletas', 'cebollín', 'cebollines',
    ],
    'cebolla': [
      'onion', 'onions', 'cebollas', 'cebolla blanca', 'cebolla morada', 'cebolla roja',
      'cebolleta', 'cebollín',
    ],
    'garlic': [
      'garlic clove', 'garlic cloves', 'garlic bulb', 'garlic bulbs',
      'minced garlic', 'garlic powder', 'garlic salt',
      // Spanish
      'ajo', 'ajos', 'diente de ajo', 'dientes de ajo', 'ajo picado', 'ajo en polvo',
    ],
    'ajo': [
      'garlic', 'garlic clove', 'garlic cloves', 'ajos', 'diente de ajo', 'dientes de ajo',
    ],
    'potato': [
      'potatoes', 'russet potato', 'russet potatoes', 'yukon potato', 'yukon potatoes',
      'red potato', 'red potatoes', 'sweet potato', 'sweet potatoes', 'baking potato',
      // Spanish
      'papa', 'papas', 'patata', 'patatas', 'papa dulce', 'camote', 'batata',
    ],
    'papa': [
      'potato', 'potatoes', 'papas', 'patata', 'patatas', 'papa dulce', 'camote',
    ],
    'pepper': [
      'bell pepper', 'bell peppers', 'red pepper', 'red peppers', 'green pepper',
      'green peppers', 'yellow pepper', 'yellow peppers', 'orange pepper',
      'sweet pepper', 'sweet peppers',
      // Spanish
      'pimiento', 'pimientos', 'pimentón', 'chile', 'chiles', 'ají', 'ajíes',
      'pimiento rojo', 'pimiento verde', 'pimiento amarillo',
    ],
    'pimiento': [
      'pepper', 'bell pepper', 'pimientos', 'pimentón', 'chile', 'ají',
    ],
    'carrot': [
      'carrots', 'baby carrot', 'baby carrots',
      // Spanish
      'zanahoria', 'zanahorias',
    ],
    'zanahoria': ['carrot', 'carrots', 'zanahorias'],
    'lettuce': [
      'lettuce leaf', 'lettuce leaves', 'romaine lettuce', 'iceberg lettuce',
      // Spanish
      'lechuga', 'lechugas', 'lechuga romana',
    ],
    'lechuga': ['lettuce', 'lechugas', 'lechuga romana'],
    'spinach': [
      'fresh spinach', 'baby spinach', 'spinach leaves',
      // Spanish
      'espinaca', 'espinacas',
    ],
    'espinaca': ['spinach', 'espinacas', 'fresh spinach', 'baby spinach'],
    'mushroom': [
      'mushrooms', 'button mushroom', 'cremini mushroom', 'portobello mushroom',
      // Spanish
      'champiñón', 'champiñones', 'hongo', 'hongos', 'seta', 'setas',
    ],
    'champiñon': ['mushroom', 'mushrooms', 'champiñones', 'hongo', 'hongos'],
    'broccoli': [
      'broccoli florets', 'broccoli crown', 'broccoli crowns',
      // Spanish
      'brócoli', 'brocoli',
    ],
    'brocoli': ['broccoli', 'brócoli', 'broccoli florets'],
    'corn': [
      'corn kernel', 'corn kernels', 'sweet corn', 'corn on the cob',
      // Spanish
      'maíz', 'elote', 'choclo', 'mazorca',
    ],
    'maiz': ['corn', 'maíz', 'elote', 'choclo', 'sweet corn'],

    // DAIRY - English & Spanish
    'milk': [
      'whole milk', 'skim milk', '2% milk', 'almond milk', 'soy milk',
      'coconut milk', 'oat milk', 'dairy milk',
      // Spanish
      'leche', 'leche entera', 'leche descremada', 'leche de almendra',
      'leche de coco', 'leche de avena',
    ],
    'leche': [
      'milk', 'whole milk', 'leche entera', 'leche descremada', 'leche de almendra',
    ],
    'cheese': [
      'cheddar cheese', 'mozzarella cheese', 'parmesan cheese', 'swiss cheese',
      'american cheese', 'provolone cheese', 'gouda cheese', 'brie cheese',
      // Spanish
      'queso', 'quesos', 'queso cheddar', 'queso mozzarella', 'queso parmesano',
      'queso fresco', 'queso oaxaca', 'queso manchego',
    ],
    'queso': [
      'cheese', 'quesos', 'queso cheddar', 'queso mozzarella', 'queso parmesano',
      'queso fresco', 'cheddar cheese', 'mozzarella cheese',
    ],
    'butter': [
      'unsalted butter', 'salted butter', 'clarified butter', 'margarine',
      'butter stick', 'butter sticks',
      // Spanish
      'mantequilla', 'manteca', 'margarina',
    ],
    'mantequilla': ['butter', 'unsalted butter', 'salted butter', 'manteca', 'margarina'],
    'egg': [
      'eggs', 'large egg', 'large eggs', 'chicken egg', 'chicken eggs',
      'whole egg', 'whole eggs',
      // Spanish
      'huevo', 'huevos', 'huevo de gallina',
    ],
    'huevo': ['egg', 'eggs', 'huevos', 'large egg', 'large eggs'],

    // MEAT - English & Spanish
    'beef': [
      'ground beef', 'beef steak', 'beef steaks', 'beef roast', 'beef roasts',
      'beef chuck', 'beef sirloin', 'beef tenderloin', 'beef brisket',
      // Spanish
      'carne de res', 'res', 'carne molida', 'bistec', 'bisteck', 'filete',
      'carne para asar', 'carne de vaca',
    ],
    'carne': [
      'beef', 'meat', 'ground beef', 'carne de res', 'carne molida', 'bistec',
      'res', 'carne de vaca',
    ],
    'pork': [
      'pork chop', 'pork chops', 'pork loin', 'pork shoulder', 'ground pork',
      'pork tenderloin', 'pork ribs', 'bacon',
      // Spanish
      'cerdo', 'carne de cerdo', 'chuleta de cerdo', 'lomo de cerdo',
      'costilla de cerdo', 'tocino', 'jamón',
    ],
    'cerdo': [
      'pork', 'pork chop', 'carne de cerdo', 'chuleta de cerdo', 'lomo de cerdo',
      'costilla de cerdo',
    ],
    'fish': [
      'salmon', 'tuna', 'cod', 'tilapia', 'white fish', 'trout', 'mackerel',
      'sardines', 'anchovy', 'anchovies',
      // Spanish
      'pescado', 'salmón', 'atún', 'bacalao', 'trucha', 'sardina', 'sardinas',
    ],
    'pescado': ['fish', 'salmon', 'tuna', 'cod', 'salmón', 'atún', 'bacalao'],

    // GRAINS - English & Spanish
    'rice': [
      'white rice', 'brown rice', 'jasmine rice', 'basmati rice',
      'wild rice', 'arborio rice', 'sushi rice',
      // Spanish
      'arroz', 'arroz blanco', 'arroz integral', 'arroz jazmín',
    ],
    'arroz': ['rice', 'white rice', 'brown rice', 'arroz blanco', 'arroz integral'],
    'pasta': [
      'spaghetti', 'penne', 'macaroni', 'fettuccine', 'linguine',
      'rigatoni', 'fusilli', 'lasagna', 'ravioli',
      // Spanish (same names mostly)
      'espagueti', 'fideos', 'tallarines',
    ],
    'flour': [
      'all purpose flour', 'all-purpose flour', 'plain flour', 'wheat flour',
      'white flour', 'bread flour', 'cake flour', 'self rising flour',
      // Spanish
      'harina', 'harina de trigo', 'harina para todo uso',
    ],
    'harina': ['flour', 'all purpose flour', 'harina de trigo', 'wheat flour'],
    'bread': [
      'bread slice', 'bread slices', 'white bread', 'wheat bread', 'sourdough bread',
      // Spanish
      'pan', 'pan blanco', 'pan integral', 'pan de caja',
    ],
    'pan': ['bread', 'white bread', 'pan blanco', 'pan integral'],

    // SEASONINGS - English & Spanish
    'sugar': [
      'white sugar', 'granulated sugar', 'brown sugar', 'cane sugar',
      'powdered sugar', 'confectioners sugar', 'raw sugar',
      // Spanish
      'azúcar', 'azucar', 'azúcar blanca', 'azúcar morena', 'azúcar glass',
    ],
    'azucar': ['sugar', 'azúcar', 'white sugar', 'brown sugar', 'azúcar blanca'],
    'oil': [
      'olive oil', 'vegetable oil', 'canola oil', 'cooking oil',
      'coconut oil', 'avocado oil', 'sunflower oil', 'peanut oil',
      // Spanish
      'aceite', 'aceite de oliva', 'aceite vegetal', 'aceite de coco',
    ],
    'aceite': ['oil', 'olive oil', 'vegetable oil', 'aceite de oliva', 'aceite vegetal'],
    'salt': [
      'table salt', 'sea salt', 'kosher salt', 'iodized salt',
      'rock salt', 'himalayan salt',
      // Spanish
      'sal', 'sal de mesa', 'sal marina', 'sal gruesa',
    ],
    'sal': ['salt', 'table salt', 'sea salt', 'sal de mesa', 'sal marina'],
    'ketchup': [
      'catsup', 'cachup', 'tomato ketchup', 'ketchup sauce',
      // Spanish
      'salsa de tomate', 'salsa catsup', 'salsa ketchup', 'catsup',
    ],
    'catsup': [
      'ketchup', 'cachup', 'tomato ketchup', 'ketchup sauce',
      // Spanish
      'salsa de tomate', 'salsa catsup', 'salsa ketchup',
    ],
    'cachup': [
      'ketchup', 'catsup', 'tomato ketchup', 'ketchup sauce',
      // Spanish
      'salsa de tomate', 'salsa catsup', 'salsa ketchup',
    ],

    // LEGUMES - English & Spanish
    'peas': [
      'pea', 'green peas', 'snow peas', 'sugar snap peas',
      // Spanish
      'chícharo', 'chícharos', 'guisante', 'guisantes', 'arveja', 'arvejas',
    ],
    'beans': [
      'bean', 'black beans', 'kidney beans', 'pinto beans', 'navy beans',
      // Spanish
      'frijol', 'frijoles', 'frijoles negros', 'habichuelas', 'judías',
      'poroto', 'porotos', 'alubias',
    ],
    'frijoles': ['beans', 'black beans', 'frijol', 'frijoles negros', 'habichuelas'],

    // OTHER
    'celery': [
      'celery stalk', 'celery stalks', 'celery rib', 'celery ribs',
      // Spanish
      'apio',
    ],
    'apio': ['celery', 'celery stalk', 'celery stalks'],
    'cauliflower': [
      'cauliflower florets', 'cauliflower head',
      // Spanish
      'coliflor',
    ],
    'coliflor': ['cauliflower', 'cauliflower florets'],
  };

  /// Normalize ingredient name for comparison
  /// Removes extra spaces, converts to lowercase, handles accents and unicode
  /// More aggressive normalization for better matching
  /// Normalize ingredient name for matching (public for use in other services)
  static String normalizeIngredientName(String name) {
    return name
        .toLowerCase()
        .trim()
        // Remove common prefixes/suffixes that don't affect matching
        .replaceAll(RegExp(r'^(fresh|dried|frozen|canned|organic|raw|cooked)\s+'), '')
        .replaceAll(RegExp(r'\s+(fresh|dried|frozen|canned|organic|raw|cooked)$'), '')
        // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove special characters but keep spaces and basic unicode letters
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]'), '') // Keep accented characters
        // Remove extra spaces again after removing special chars
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extract words from ingredient name
  static List<String> _extractWords(String name) {
    final normalized = normalizeIngredientName(name);
    return normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// Check if one ingredient name is a subset of another (word-based matching)
  /// Example: "chicken" matches "chicken breast" because "chicken" is a word in "chicken breast"
  /// Also works bidirectionally: "chicken breast" matches "chicken" if chicken is the main word
  static bool _isWordSubset(String shorter, String longer) {
    final shorterWords = _extractWords(shorter);
    final longerWords = _extractWords(longer);
    
    if (shorterWords.isEmpty || longerWords.isEmpty) return false;
    
    // If shorter has only one word, check if it matches any word in longer
    if (shorterWords.length == 1) {
      final singleWord = shorterWords[0];
      // Check if this word appears as an exact word match in longer
      for (final longWord in longerWords) {
        // Exact word match (e.g., "chicken" matches "chicken" in "chicken breast")
        if (longWord == singleWord) {
          return true;
        }
        // Word contains the shorter word as a complete word (e.g., "chicken" in "chickenbreast")
        // Use word boundary to ensure it's a complete word, not just a substring
        if (longWord.length >= singleWord.length && 
            (longWord == singleWord || 
             longWord.startsWith(singleWord) || 
             longWord.endsWith(singleWord) ||
             longWord.contains(singleWord))) {
          // Additional check: ensure it's not just a very short substring match
          if (singleWord.length >= 3) {
            return true;
          }
        }
        // Shorter word contains longer word (e.g., "chicken" contains "chick" - but this is less reliable)
        if (singleWord.length > longWord.length && 
            singleWord.contains(longWord) && 
            longWord.length >= 4) {
          return true;
        }
      }
    }
    
    // Check if all words in shorter are present in longer
    int matchedWords = 0;
    for (final word in shorterWords) {
      if (word.length < 3) continue; // Skip very short words
      
      bool found = false;
      for (final longWord in longerWords) {
        // Exact word match
        if (word == longWord) {
          found = true;
          matchedWords++;
          break;
        }
        // Word contains the shorter word (e.g., "chicken" in "chickenbreast")
        if (longWord.contains(word) && word.length >= 3) {
          found = true;
          matchedWords++;
          break;
        }
        // Shorter word contains longer word (partial match) - be more strict
        if (word.contains(longWord) && longWord.length >= 4) {
          found = true;
          matchedWords++;
          break;
        }
      }
    }
    
    // Match if at least 50% of significant words match, or if all words match
    final significantWords = shorterWords.where((w) => w.length >= 3).length;
    if (significantWords == 0) return false; // No significant words to match
    
    return matchedWords >= (significantWords * 0.5) || matchedWords == shorterWords.length;
  }

  /// Check if two ingredient names match (fuzzy matching with improved logic)
  /// Handles flexible matching like "chicken" ↔ "chicken breast"
  /// Public for use in other services (e.g., shopping list generation)
  static bool ingredientNamesMatch(String name1, String name2) {
    final normalized1 = normalizeIngredientName(name1);
    final normalized2 = normalizeIngredientName(name2);

    // Exact match after normalization (most reliable)
    if (normalized1 == normalized2) {
      Logger.info('Exact normalized match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }

    // Check synonyms first (most reliable after exact match)
    if (_checkSynonyms(normalized1, normalized2)) {
      Logger.info('Synonym match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }

    // Determine shorter and longer strings
    final shorter = normalized1.length < normalized2.length ? normalized1 : normalized2;
    final longer = normalized1.length >= normalized2.length ? normalized1 : normalized2;
    
    // Word-based subset matching (e.g., "chicken" matches "chicken breast")
    // This is bidirectional - works both ways
    if (_isWordSubset(shorter, longer)) {
      Logger.info('Word subset match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }
    
    // Also try the reverse - sometimes longer word might be subset of shorter
    if (shorter != longer && _isWordSubset(longer, shorter)) {
      Logger.info('Reverse word subset match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }

    // Check if one contains the other as substring (more lenient)
    // But be careful - only match if it's a meaningful substring
    if (longer.contains(shorter)) {
      // For substring matches, require shorter to be at least 4 characters
      // or at least 50% of longer (stricter to avoid false positives)
      if (shorter.length >= 4 && shorter.length >= (longer.length * 0.5)) {
        Logger.info('Substring match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
        return true;
      }
    }
    
    // Also check if shorter contains longer (partial match) - be very strict
    if (shorter.contains(longer) && longer.length >= 4) {
      Logger.info('Reverse substring match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }

    // Handle plural/singular variations
    final singular1 = normalized1.replaceAll(RegExp(r's$'), '');
    final singular2 = normalized2.replaceAll(RegExp(r's$'), '');
    if (singular1 == singular2 && singular1.length > 3) {
      Logger.info('Singular/plural match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }
    
    // Check if singular forms match as word subsets
    if (_isWordSubset(
      singular1.length < singular2.length ? singular1 : singular2,
      singular1.length >= singular2.length ? singular1 : singular2,
    )) {
      Logger.info('Singular word subset match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }

    // Handle common word endings (e.g., "ed", "ing")
    final base1 = singular1.replaceAll(RegExp(r'(ed|ing)$'), '');
    final base2 = singular2.replaceAll(RegExp(r'(ed|ing)$'), '');
    if (base1 == base2 && base1.length > 3) {
      Logger.info('Base form match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
      return true;
    }
    
    // Check if base forms match as word subsets
    if (base1.length > 3 && base2.length > 3) {
      if (_isWordSubset(
        base1.length < base2.length ? base1 : base2,
        base1.length >= base2.length ? base1 : base2,
      )) {
        Logger.info('Base word subset match: "$name1" ↔ "$name2"', 'RecipeRecommendationService');
        return true;
      }
    }

    // Try matching individual words - if any significant word matches, consider it a match
    final words1 = _extractWords(normalized1);
    final words2 = _extractWords(normalized2);
    
    // If both have words, check for word overlap
    if (words1.isNotEmpty && words2.isNotEmpty) {
      int matchingWords = 0;
      for (final word1 in words1) {
        if (word1.length < 3) continue; // Skip very short words
        for (final word2 in words2) {
          if (word2.length < 3) continue;
          // Exact word match
          if (word1 == word2) {
            matchingWords++;
            break;
          }
          // One word contains the other (be more strict)
          if ((word1.contains(word2) || word2.contains(word1)) && 
              (word1.length >= 3 && word2.length >= 3) &&
              (word1.length >= word2.length * 0.7 || word2.length >= word1.length * 0.7)) {
            matchingWords++;
            break;
          }
        }
      }
      // If at least 50% of significant words match, consider it a match
      final significantWords1 = words1.where((w) => w.length >= 3).length;
      if (significantWords1 > 0 && matchingWords > 0 && matchingWords >= (significantWords1 * 0.5).ceil()) {
        Logger.info('Word overlap match: "$name1" ↔ "$name2" ($matchingWords words)', 'RecipeRecommendationService');
        return true;
      }
    }

    return false;
  }

  /// Check if two ingredients match through synonyms
  /// Note: name1 and name2 should already be normalized
  static bool _checkSynonyms(String name1, String name2) {
    // Normalize the names if they aren't already (defensive)
    final norm1 = normalizeIngredientName(name1);
    final norm2 = normalizeIngredientName(name2);
    
    // Check direct synonym matches
    for (final entry in _ingredientSynonyms.entries) {
      final base = entry.key;
      final synonyms = entry.value;
      final normalizedBase = normalizeIngredientName(base);
      
      // Check if name1 matches base and name2 matches any synonym (or vice versa)
      if (normalizedBase == norm1) {
        for (final synonym in synonyms) {
          final normalizedSynonym = normalizeIngredientName(synonym);
          if (normalizedSynonym == norm2) {
            Logger.info('Synonym match (base-synonym): "$name1" ↔ "$name2" (base: "$base")', 'RecipeRecommendationService');
            return true;
          }
        }
      }
      if (normalizedBase == norm2) {
        for (final synonym in synonyms) {
          final normalizedSynonym = normalizeIngredientName(synonym);
          if (normalizedSynonym == norm1) {
            Logger.info('Synonym match (synonym-base): "$name1" ↔ "$name2" (base: "$base")', 'RecipeRecommendationService');
            return true;
          }
        }
      }
      
      // Check if both match synonyms of the same base
      bool name1Matches = false;
      bool name2Matches = false;
      
      if (normalizedBase == norm1) {
        name1Matches = true;
      } else {
        for (final synonym in synonyms) {
          final normalizedSynonym = normalizeIngredientName(synonym);
          if (normalizedSynonym == norm1) {
            name1Matches = true;
            break;
          }
        }
      }
      
      if (normalizedBase == norm2) {
        name2Matches = true;
      } else {
        for (final synonym in synonyms) {
          final normalizedSynonym = normalizeIngredientName(synonym);
          if (normalizedSynonym == norm2) {
            name2Matches = true;
            break;
          }
        }
      }
      
      if (name1Matches && name2Matches) {
        Logger.info('Synonym match (both synonyms): "$name1" ↔ "$name2" (base: "$base")', 'RecipeRecommendationService');
        return true;
      }
    }

    return false;
  }

  /// Get recommended recipes based on pantry items
  /// Returns recipes that have at least one matching ingredient OR meet minimum coverage threshold
  /// Calculates coverage percentage based on matched ingredients / total ingredients
  static List<RecipeRecommendation> getRecommendedRecipes({
    required List<PantryItem> pantryItems,
    required List<Recipe> allRecipes,
    double minCoverage = 0.10, // Minimum 10% match required (very lenient - ensures recipes show up)
  }) {
    try {
      if (pantryItems.isEmpty) {
        Logger.info('No pantry items available for recommendations', 'RecipeRecommendationService');
        return [];
      }

      if (allRecipes.isEmpty) {
        Logger.info('No recipes available for recommendations', 'RecipeRecommendationService');
        return [];
      }

      // Create a map of pantry items by normalized name for quick lookup
      final pantryMap = <String, PantryItem>{};
      for (final item in pantryItems) {
        final normalizedName = normalizeIngredientName(item.name);
        // Store the first occurrence (or could use quantity-based logic)
        if (!pantryMap.containsKey(normalizedName)) {
          pantryMap[normalizedName] = item;
        }
      }

      final recommendations = <RecipeRecommendation>[];

      for (final recipe in allRecipes) {
        if (recipe.ingredients.isEmpty) continue;

        final availableIngredients = <RecipeIngredient>[];
        final missingIngredients = <RecipeIngredient>[];

        // Check each recipe ingredient against pantry items
        // Use normalized pantry map for faster lookup
        Logger.info(
          'Checking recipe "${recipe.title}" with ${recipe.ingredients.length} ingredients',
          'RecipeRecommendationService',
        );
        
        for (final recipeIngredient in recipe.ingredients) {
          bool found = false;
          final normalizedRecipeIngredient = normalizeIngredientName(recipeIngredient.name);

          // First try exact match in pantry map
          if (pantryMap.containsKey(normalizedRecipeIngredient)) {
            availableIngredients.add(recipeIngredient);
            found = true;
            Logger.info(
              'Exact match: "${recipeIngredient.name}" ↔ "${pantryMap[normalizedRecipeIngredient]!.name}"',
              'RecipeRecommendationService',
            );
          } else {
            // Try fuzzy matching against all pantry items
            for (final pantryItem in pantryItems) {
              final pantryNormalized = normalizeIngredientName(pantryItem.name);
              
              // Try matching both ways (recipe ingredient vs pantry item)
              if (ingredientNamesMatch(recipeIngredient.name, pantryItem.name) ||
                  ingredientNamesMatch(pantryItem.name, recipeIngredient.name)) {
                availableIngredients.add(recipeIngredient);
                found = true;
                // Log successful match for debugging
                Logger.info(
                  'Fuzzy match: "${recipeIngredient.name}" ↔ "${pantryItem.name}"',
                  'RecipeRecommendationService',
                );
                break;
              }
            }
            
            if (!found) {
              Logger.info(
                'No match found for recipe ingredient: "${recipeIngredient.name}" (normalized: "$normalizedRecipeIngredient")',
                'RecipeRecommendationService',
              );
            }
          }

          if (!found) {
            missingIngredients.add(recipeIngredient);
          }
        }
        
        Logger.info(
          'Recipe "${recipe.title}": ${availableIngredients.length} available, ${missingIngredients.length} missing',
          'RecipeRecommendationService',
        );

        // Calculate coverage percentage: matched ingredients / total ingredients
        final totalIngredients = recipe.ingredients.length;
        final matchedCount = availableIngredients.length;
        
        // Coverage is the ratio of matched ingredients to total ingredients
        // This gives us: 0.0 (0%) to 1.0 (100%)
        final coverage = totalIngredients > 0 
            ? (matchedCount / totalIngredients).clamp(0.0, 1.0)
            : 0.0;

        // Include recipes that have at least one matching ingredient
        // This ensures that if "chicken" is in pantry and recipe has "chicken", it will be suggested
        // regardless of how many other ingredients the recipe has
        if (availableIngredients.isNotEmpty) {
          Logger.info(
            'Adding recommendation: "${recipe.title}" - Coverage: ${(coverage * 100).toStringAsFixed(1)}%, Matched: ${availableIngredients.length}/${totalIngredients}',
            'RecipeRecommendationService',
          );
          recommendations.add(RecipeRecommendation(
            recipe: recipe,
            coveragePercentage: coverage,
            availableIngredients: availableIngredients,
            missingIngredients: missingIngredients,
          ));
        } else {
          Logger.info(
            'Skipping recipe "${recipe.title}" - No matching ingredients found',
            'RecipeRecommendationService',
          );
        }
      }

      // Sort by match probability (coverage percentage) - highest first, then by number of matches
      recommendations.sort((a, b) {
        // Primary sort: coverage percentage (match probability)
        final coverageCompare = b.coveragePercentage.compareTo(a.coveragePercentage);
        if (coverageCompare != 0) return coverageCompare;
        
        // Secondary sort: number of matched ingredients
        final matchCountCompare = b.availableIngredients.length.compareTo(a.availableIngredients.length);
        if (matchCountCompare != 0) return matchCountCompare;
        
        // Tertiary sort: recipe title
        return a.recipe.title.compareTo(b.recipe.title);
      });

      Logger.success(
        'Found ${recommendations.length} recommended recipes with matching ingredients (from ${allRecipes.length} total recipes)',
        'RecipeRecommendationService',
      );
      
      if (recommendations.isEmpty && pantryItems.isNotEmpty) {
        Logger.warning(
          'No recommendations found despite having ${pantryItems.length} pantry items. Pantry items: ${pantryItems.map((p) => p.name).join(", ")}',
          'RecipeRecommendationService',
        );
      }

      return recommendations;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get recommended recipes',
        e,
        stackTrace,
        'RecipeRecommendationService',
      );
      return [];
    }
  }

}

