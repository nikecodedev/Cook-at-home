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
  /// Common ingredient synonyms and variations
  /// Expanded with more variations for better matching
  static final Map<String, List<String>> _ingredientSynonyms = {
    'chicken': [
      'chicken breast', 'chicken breasts', 'chicken thigh', 'chicken thighs', 
      'chicken wing', 'chicken wings', 'chicken drumstick', 'chicken drumsticks',
      'whole chicken', 'chicken pieces', 'chicken meat', 'boneless chicken',
      'skinless chicken', 'chicken fillet', 'chicken fillets'
    ],
    'tomato': [
      'tomatoes', 'cherry tomato', 'cherry tomatoes', 'roma tomato', 'roma tomatoes',
      'plum tomato', 'plum tomatoes', 'beefsteak tomato', 'grape tomato'
    ],
    'onion': [
      'onions', 'yellow onion', 'yellow onions', 'white onion', 'white onions',
      'red onion', 'red onions', 'sweet onion', 'sweet onions', 'green onion',
      'green onions', 'scallion', 'scallions'
    ],
    'garlic': [
      'garlic clove', 'garlic cloves', 'garlic bulb', 'garlic bulbs',
      'minced garlic', 'garlic powder', 'garlic salt'
    ],
    'potato': [
      'potatoes', 'russet potato', 'russet potatoes', 'yukon potato', 'yukon potatoes',
      'red potato', 'red potatoes', 'sweet potato', 'sweet potatoes', 'baking potato'
    ],
    'pepper': [
      'bell pepper', 'bell peppers', 'red pepper', 'red peppers', 'green pepper',
      'green peppers', 'yellow pepper', 'yellow peppers', 'orange pepper',
      'sweet pepper', 'sweet peppers'
    ],
    'milk': [
      'whole milk', 'skim milk', '2% milk', 'almond milk', 'soy milk',
      'coconut milk', 'oat milk', 'dairy milk'
    ],
    'cheese': [
      'cheddar cheese', 'mozzarella cheese', 'parmesan cheese', 'swiss cheese',
      'american cheese', 'provolone cheese', 'gouda cheese', 'brie cheese'
    ],
    'butter': [
      'unsalted butter', 'salted butter', 'clarified butter', 'margarine',
      'butter stick', 'butter sticks'
    ],
    'flour': [
      'all purpose flour', 'all-purpose flour', 'plain flour', 'wheat flour',
      'white flour', 'bread flour', 'cake flour', 'self rising flour'
    ],
    'sugar': [
      'white sugar', 'granulated sugar', 'brown sugar', 'cane sugar',
      'powdered sugar', 'confectioners sugar', 'raw sugar'
    ],
    'oil': [
      'olive oil', 'vegetable oil', 'canola oil', 'cooking oil',
      'coconut oil', 'avocado oil', 'sunflower oil', 'peanut oil'
    ],
    'salt': [
      'table salt', 'sea salt', 'kosher salt', 'iodized salt',
      'rock salt', 'himalayan salt'
    ],
    'egg': [
      'eggs', 'large egg', 'large eggs', 'chicken egg', 'chicken eggs',
      'whole egg', 'whole eggs'
    ],
    'beef': [
      'ground beef', 'beef steak', 'beef steaks', 'beef roast', 'beef roasts',
      'beef chuck', 'beef sirloin', 'beef tenderloin', 'beef brisket'
    ],
    'pork': [
      'pork chop', 'pork chops', 'pork loin', 'pork shoulder', 'ground pork',
      'pork tenderloin', 'pork ribs', 'bacon'
    ],
    'fish': [
      'salmon', 'tuna', 'cod', 'tilapia', 'white fish', 'trout', 'mackerel',
      'sardines', 'anchovy', 'anchovies'
    ],
    'rice': [
      'white rice', 'brown rice', 'jasmine rice', 'basmati rice',
      'wild rice', 'arborio rice', 'sushi rice'
    ],
    'pasta': [
      'spaghetti', 'penne', 'macaroni', 'fettuccine', 'linguine',
      'rigatoni', 'fusilli', 'lasagna', 'ravioli'
    ],
    'carrot': ['carrots', 'baby carrot', 'baby carrots'],
    'celery': ['celery stalk', 'celery stalks', 'celery rib', 'celery ribs'],
    'lettuce': ['lettuce leaf', 'lettuce leaves', 'romaine lettuce', 'iceberg lettuce'],
    'spinach': ['fresh spinach', 'baby spinach', 'spinach leaves'],
    'mushroom': ['mushrooms', 'button mushroom', 'cremini mushroom', 'portobello mushroom'],
    'broccoli': ['broccoli florets', 'broccoli crown', 'broccoli crowns'],
    'cauliflower': ['cauliflower florets', 'cauliflower head'],
    'corn': ['corn kernel', 'corn kernels', 'sweet corn', 'corn on the cob'],
    'peas': ['pea', 'green peas', 'snow peas', 'sugar snap peas'],
    'beans': ['bean', 'black beans', 'kidney beans', 'pinto beans', 'navy beans'],
    'bread': ['bread slice', 'bread slices', 'white bread', 'wheat bread', 'sourdough bread'],
  };

  /// Normalize ingredient name for comparison
  /// Removes extra spaces, converts to lowercase, handles accents and unicode
  /// More aggressive normalization for better matching
  static String _normalizeIngredientName(String name) {
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
    final normalized = _normalizeIngredientName(name);
    return normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// Check if one ingredient name is a subset of another (word-based matching)
  /// Example: "chicken" matches "chicken breast" because "chicken" is a word in "chicken breast"
  /// Also works bidirectionally: "chicken breast" matches "chicken" if chicken is the main word
  static bool _isWordSubset(String shorter, String longer) {
    final shorterWords = _extractWords(shorter);
    final longerWords = _extractWords(longer);
    
    if (shorterWords.isEmpty || longerWords.isEmpty) return false;
    
    // If shorter has only one word and it's in longer, it's a match
    if (shorterWords.length == 1) {
      final singleWord = shorterWords[0];
      // Check if this word appears in any of the longer words
      for (final longWord in longerWords) {
        // Exact word match
        if (longWord == singleWord) {
          return true;
        }
        // Word contains the shorter word (e.g., "chicken" in "chickenbreast")
        if (longWord.contains(singleWord) && singleWord.length >= 3) {
          return true;
        }
        // Shorter word contains longer word (e.g., "chicken" contains "chick")
        if (singleWord.contains(longWord) && longWord.length >= 3) {
          return true;
        }
      }
    }
    
    // Check if all words in shorter are present in longer
    int matchedWords = 0;
    for (final word in shorterWords) {
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
        // Shorter word contains longer word (partial match)
        if (word.contains(longWord) && longWord.length >= 3) {
          found = true;
          matchedWords++;
          break;
        }
      }
    }
    
    // Match if at least 50% of words match, or if all words match
    return matchedWords >= (shorterWords.length * 0.5) || matchedWords == shorterWords.length;
  }

  /// Check if two ingredient names match (fuzzy matching with improved logic)
  /// Handles flexible matching like "chicken" ↔ "chicken breast"
  static bool _ingredientNamesMatch(String name1, String name2) {
    final normalized1 = _normalizeIngredientName(name1);
    final normalized2 = _normalizeIngredientName(name2);

    // Exact match after normalization
    if (normalized1 == normalized2) return true;

    // Check synonyms first (most reliable)
    if (_checkSynonyms(normalized1, normalized2)) return true;

    // Determine shorter and longer strings
    final shorter = normalized1.length < normalized2.length ? normalized1 : normalized2;
    final longer = normalized1.length >= normalized2.length ? normalized1 : normalized2;
    
    // Word-based subset matching (e.g., "chicken" matches "chicken breast")
    // This is bidirectional - works both ways
    if (_isWordSubset(shorter, longer)) return true;
    
    // Also try the reverse - sometimes longer word might be subset of shorter
    if (shorter != longer && _isWordSubset(longer, shorter)) return true;

    // Check if one contains the other as substring (more lenient)
    if (longer.contains(shorter)) {
      // For substring matches, require shorter to be at least 3 characters
      // or at least 40% of longer (more lenient than before)
      if (shorter.length >= 3 || shorter.length >= (longer.length * 0.4)) {
        return true;
      }
    }
    
    // Also check if shorter contains longer (partial match)
    if (shorter.contains(longer) && longer.length >= 3) {
      return true;
    }

    // Handle plural/singular variations
    final singular1 = normalized1.replaceAll(RegExp(r's$'), '');
    final singular2 = normalized2.replaceAll(RegExp(r's$'), '');
    if (singular1 == singular2 && singular1.length > 2) return true;
    
    // Check if singular forms match as word subsets
    if (_isWordSubset(
      singular1.length < singular2.length ? singular1 : singular2,
      singular1.length >= singular2.length ? singular1 : singular2,
    )) return true;

    // Handle common word endings (e.g., "ed", "ing")
    final base1 = singular1.replaceAll(RegExp(r'(ed|ing)$'), '');
    final base2 = singular2.replaceAll(RegExp(r'(ed|ing)$'), '');
    if (base1 == base2 && base1.length > 3) return true;
    
    // Check if base forms match as word subsets
    if (base1.length > 3 && base2.length > 3) {
      if (_isWordSubset(
        base1.length < base2.length ? base1 : base2,
        base1.length >= base2.length ? base1 : base2,
      )) return true;
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
          // One word contains the other
          if ((word1.contains(word2) || word2.contains(word1)) && 
              (word1.length >= 3 && word2.length >= 3)) {
            matchingWords++;
            break;
          }
        }
      }
      // If at least one significant word matches, consider it a match
      if (matchingWords > 0 && matchingWords >= (words1.length * 0.5).ceil()) {
        return true;
      }
    }

    return false;
  }

  /// Check if two ingredients match through synonyms
  static bool _checkSynonyms(String name1, String name2) {
    // Check direct synonym matches
    for (final entry in _ingredientSynonyms.entries) {
      final base = entry.key;
      final synonyms = entry.value;
      
      // Check if name1 matches base and name2 matches any synonym (or vice versa)
      if (_normalizeIngredientName(base) == name1) {
        for (final synonym in synonyms) {
          if (_normalizeIngredientName(synonym) == name2) return true;
        }
      }
      if (_normalizeIngredientName(base) == name2) {
        for (final synonym in synonyms) {
          if (_normalizeIngredientName(synonym) == name1) return true;
        }
      }
      
      // Check if both match synonyms of the same base
      bool name1Matches = false;
      bool name2Matches = false;
      
      if (_normalizeIngredientName(base) == name1) {
        name1Matches = true;
      } else {
        for (final synonym in synonyms) {
          if (_normalizeIngredientName(synonym) == name1) {
            name1Matches = true;
            break;
          }
        }
      }
      
      if (_normalizeIngredientName(base) == name2) {
        name2Matches = true;
      } else {
        for (final synonym in synonyms) {
          if (_normalizeIngredientName(synonym) == name2) {
            name2Matches = true;
            break;
          }
        }
      }
      
      if (name1Matches && name2Matches) return true;
    }

    return false;
  }

  /// Get recommended recipes based on pantry items
  /// Returns recipes that have at least 15% matching ingredients (configurable)
  /// Calculates coverage percentage based on matched ingredients / total ingredients
  static List<RecipeRecommendation> getRecommendedRecipes({
    required List<PantryItem> pantryItems,
    required List<Recipe> allRecipes,
    double minCoverage = 0.15, // Minimum 15% match required (more lenient)
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
        final normalizedName = _normalizeIngredientName(item.name);
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
        for (final recipeIngredient in recipe.ingredients) {
          bool found = false;
          final normalizedRecipeIngredient = _normalizeIngredientName(recipeIngredient.name);

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
              if (_ingredientNamesMatch(recipeIngredient.name, pantryItem.name)) {
                availableIngredients.add(recipeIngredient);
                found = true;
                // Log successful match for debugging
                Logger.info(
                  'Matched: "${recipeIngredient.name}" ↔ "${pantryItem.name}"',
                  'RecipeRecommendationService',
                );
                break;
              }
            }
          }

          if (!found) {
            missingIngredients.add(recipeIngredient);
          }
        }

        // Calculate coverage percentage: matched ingredients / total ingredients
        final totalIngredients = recipe.ingredients.length;
        final matchedCount = availableIngredients.length;
        
        // Coverage is the ratio of matched ingredients to total ingredients
        // This gives us: 0.0 (0%) to 1.0 (100%)
        final coverage = totalIngredients > 0 
            ? (matchedCount / totalIngredients).clamp(0.0, 1.0)
            : 0.0;

        // Only include recipes that meet minimum coverage threshold (25% by default)
        // This ensures recipes only show up with valid matches
        if (coverage >= minCoverage && availableIngredients.isNotEmpty) {
          recommendations.add(RecipeRecommendation(
            recipe: recipe,
            coveragePercentage: coverage,
            availableIngredients: availableIngredients,
            missingIngredients: missingIngredients,
          ));
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
        'Found ${recommendations.length} recommended recipes with matching ingredients',
        'RecipeRecommendationService',
      );

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

