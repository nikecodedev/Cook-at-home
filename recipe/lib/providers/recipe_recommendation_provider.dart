import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recipe_recommendation_service.dart';
import '../models/recipe_model.dart';
import '../models/pantry_item_model.dart';
import 'profile_provider.dart';
import '../core/utils/logger.dart';

/// Combines two streams and emits whenever either stream emits a new value
/// This is equivalent to RxDart's combineLatest2 but using native Dart
Stream<List<RecipeRecommendation>> _combineStreams(
  Stream<List<PantryItem>> pantryStream,
  Stream<List<Recipe>> recipesStream,
) {
  final controller = StreamController<List<RecipeRecommendation>>();
  List<PantryItem>? latestPantryItems;
  List<Recipe>? latestRecipes;
  bool pantryHasValue = false;
  bool recipesHasValue = false;
  bool pantryDone = false;
  bool recipesDone = false;

  void emitIfReady() {
    if (pantryHasValue && recipesHasValue && latestPantryItems != null && latestRecipes != null) {
      try {
        final recommendations = _processRecommendations(latestPantryItems!, latestRecipes!);
        if (!controller.isClosed) {
          controller.add(recommendations);
        }
      } catch (e, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(e, stackTrace);
        }
      }
    }
  }

  void checkDone() {
    if (pantryDone && recipesDone && !controller.isClosed) {
      controller.close();
    }
  }

  final pantrySubscription = pantryStream.listen(
    (items) {
      latestPantryItems = items;
      pantryHasValue = true;
      emitIfReady();
    },
    onError: (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    },
    onDone: () {
      pantryDone = true;
      checkDone();
    },
    cancelOnError: false,
  );

  final recipesSubscription = recipesStream.listen(
    (items) {
      latestRecipes = items;
      recipesHasValue = true;
      emitIfReady();
    },
    onError: (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    },
    onDone: () {
      recipesDone = true;
      checkDone();
    },
    cancelOnError: false,
  );

  controller.onCancel = () {
    pantrySubscription.cancel();
    recipesSubscription.cancel();
    if (!controller.isClosed) {
      controller.close();
    }
  };

  return controller.stream;
}

/// Process recommendations from pantry items and recipes
List<RecipeRecommendation> _processRecommendations(
  List<PantryItem> pantryItems,
  List<Recipe> recipes,
) {
  Logger.info(
    'Combining streams: ${pantryItems.length} pantry items, ${recipes.length} recipes',
    'RecipeRecommendationProvider',
  );

  if (pantryItems.isNotEmpty) {
    Logger.info(
      'Pantry items: ${pantryItems.map((item) => item.name).join(", ")}',
      'RecipeRecommendationProvider',
    );
  }

  if (pantryItems.isEmpty) {
    Logger.info('No pantry items, returning empty recommendations', 'RecipeRecommendationProvider');
    return <RecipeRecommendation>[];
  }

  if (recipes.isEmpty) {
    Logger.info('No recipes, returning empty recommendations', 'RecipeRecommendationProvider');
    return <RecipeRecommendation>[];
  }

  final recommendations = RecipeRecommendationService.getRecommendedRecipes(
    pantryItems: pantryItems,
    allRecipes: recipes,
    minCoverage: 0.0, // No minimum - show any recipe with at least one matching ingredient
  );

  Logger.info(
    'Found ${recommendations.length} recommended recipes',
    'RecipeRecommendationProvider',
  );

  if (recommendations.isNotEmpty) {
    Logger.info(
      'Top recommendations: ${recommendations.take(3).map((r) => "${r.recipe.title} (${r.coveragePercent}%)").join(", ")}',
      'RecipeRecommendationProvider',
    );
  } else if (pantryItems.isNotEmpty && recipes.isNotEmpty) {
    // Debug: Log why no matches were found
    Logger.warning(
      'No recommendations found despite having pantry items and recipes. '
      'Pantry: ${pantryItems.map((p) => p.name).join(", ")}. '
      'Sample recipes: ${recipes.take(3).map((r) => r.title).join(", ")}',
      'RecipeRecommendationProvider',
    );
  }

  return recommendations;
}

/// Provider for recipe recommendations stream
/// Combines pantry items and recipes streams to provide real-time recommendations
/// Uses native Dart streams to react to changes in either stream
final recipeRecommendationsStreamProvider =
    StreamProvider<List<RecipeRecommendation>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    Logger.info('No user ID, returning empty recommendations', 'RecipeRecommendationProvider');
    return Stream.value(<RecipeRecommendation>[]);
  }

  // Get both streams
  final pantryStream = firestoreService.streamPantryItems(userId);
  final recipesStream = firestoreService.streamAllRecipes();

  // Combine both streams using native Dart - this ensures we react to changes in either stream
  return _combineStreams(pantryStream, recipesStream).handleError((error, stackTrace) {
    Logger.error(
      'Error in recipe recommendations stream',
      error,
      stackTrace,
      'RecipeRecommendationProvider',
    );
    return <RecipeRecommendation>[];
  });
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
      minCoverage: 0.10, // Minimum 10% match required (very lenient - shows recipes with any match)
    );
  } catch (e) {
    return [];
  }
});

