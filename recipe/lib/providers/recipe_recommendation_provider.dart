import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_recommendation_service.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import 'recipe_provider.dart';
import 'pantry_provider.dart';
import 'profile_provider.dart';
import '../services/firestore/firestore_service.dart';
import '../core/utils/logger.dart';

/// Provider for recipe recommendations stream
/// Combines pantry items and recipes streams to provide real-time recommendations
final recipeRecommendationsStreamProvider =
    StreamProvider<List<RecipeRecommendation>>((ref) {
  final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);
  final recipesAsync = ref.watch(allRecipesStreamProvider);

  // Wait for both streams to have data
  return pantryItemsAsync.when(
    data: (pantryItems) {
      // Log pantry items for debugging
      Logger.info('Pantry items loaded: ${pantryItems.length} items', 'RecipeRecommendationProvider');
      if (pantryItems.isNotEmpty) {
        Logger.info('Pantry items: ${pantryItems.map((item) => item.name).join(", ")}', 'RecipeRecommendationProvider');
      }
      
      return recipesAsync.when(
        data: (recipes) {
          Logger.info('Recipes loaded: ${recipes.length} recipes', 'RecipeRecommendationProvider');
          
          final recommendations = RecipeRecommendationService.getRecommendedRecipes(
            pantryItems: pantryItems,
            allRecipes: recipes,
            minCoverage: 0.15, // Minimum 15% match required (more lenient for better suggestions)
          );
          
          Logger.info('Found ${recommendations.length} recommended recipes', 'RecipeRecommendationProvider');
          if (recommendations.isNotEmpty) {
            Logger.info('Top recommendations: ${recommendations.take(3).map((r) => "${r.recipe.title} (${r.coveragePercent}%)").join(", ")}', 'RecipeRecommendationProvider');
          }
          
          return Stream.value(recommendations);
        },
        loading: () {
          Logger.info('Recipes still loading...', 'RecipeRecommendationProvider');
          return Stream.value(<RecipeRecommendation>[]);
        },
        error: (error, stackTrace) {
          Logger.error('Error loading recipes for recommendations', error, stackTrace, 'RecipeRecommendationProvider');
          return Stream.value(<RecipeRecommendation>[]);
        },
      );
    },
    loading: () {
      Logger.info('Pantry items still loading...', 'RecipeRecommendationProvider');
      return Stream.value(<RecipeRecommendation>[]);
    },
    error: (error, stackTrace) {
      Logger.error('Error loading pantry items for recommendations', error, stackTrace, 'RecipeRecommendationProvider');
      return Stream.value(<RecipeRecommendation>[]);
    },
  );
});

/// Provider for recipe recommendations (non-stream, for one-time fetch)
final recipeRecommendationsProvider =
    FutureProvider<List<RecipeRecommendation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // Fetch pantry items and recipes
    final pantryItems = await firestoreService.getPantryItems(userId);
    final recipes = await firestoreService.getAllRecipes();

    return RecipeRecommendationService.getRecommendedRecipes(
      pantryItems: pantryItems,
      allRecipes: recipes,
      minCoverage: 0.15, // Minimum 15% match required (more lenient for better suggestions)
    );
  } catch (e) {
    return [];
  }
});

