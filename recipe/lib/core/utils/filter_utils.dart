import '../../models/pantry_item_model.dart';
import '../../models/recipe_model.dart';

/// Filter options for pantry items
class PantryFilter {
  final String? category;
  final ExpirationFilter? expirationStatus;
  final String? searchQuery;

  PantryFilter({
    this.category,
    this.expirationStatus,
    this.searchQuery,
  });

  PantryFilter copyWith({
    String? category,
    ExpirationFilter? expirationStatus,
    String? searchQuery,
  }) {
    return PantryFilter(
      category: category ?? this.category,
      expirationStatus: expirationStatus ?? this.expirationStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        expirationStatus != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  List<PantryItem> applyFilters(List<PantryItem> items) {
    var filtered = List<PantryItem>.from(items);

    // Apply search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase().trim();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (category != null && category!.isNotEmpty) {
      filtered = filtered.where((item) => item.category == category).toList();
    }

    // Apply expiration status filter
    if (expirationStatus != null) {
      switch (expirationStatus!) {
        case ExpirationFilter.expired:
          filtered = filtered.where((item) => item.isExpired).toList();
          break;
        case ExpirationFilter.expiringSoon:
          filtered = filtered.where((item) => item.isExpiringSoon && !item.isExpired).toList();
          break;
        case ExpirationFilter.normal:
          filtered = filtered.where((item) => !item.isExpiringSoon && !item.isExpired).toList();
          break;
        case ExpirationFilter.all:
          // No filter
          break;
      }
    }

    return filtered;
  }
}

/// Filter options for recipes
class RecipeFilter {
  final CookTimeFilter? cookTime;
  final String? searchQuery;
  final int? minIngredients;
  final int? maxIngredients;

  RecipeFilter({
    this.cookTime,
    this.searchQuery,
    this.minIngredients,
    this.maxIngredients,
  });

  RecipeFilter copyWith({
    CookTimeFilter? cookTime,
    String? searchQuery,
    int? minIngredients,
    int? maxIngredients,
  }) {
    return RecipeFilter(
      cookTime: cookTime ?? this.cookTime,
      searchQuery: searchQuery ?? this.searchQuery,
      minIngredients: minIngredients ?? this.minIngredients,
      maxIngredients: maxIngredients ?? this.maxIngredients,
    );
  }

  bool get hasActiveFilters {
    return cookTime != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        minIngredients != null ||
        maxIngredients != null;
  }

  List<Recipe> applyFilters(List<Recipe> recipes) {
    var filtered = List<Recipe>.from(recipes);

    // Apply search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase().trim();
      filtered = filtered.where((recipe) {
        // Search in title
        if (recipe.title.toLowerCase().contains(query)) {
          return true;
        }
        // Search in ingredients
        for (final ingredient in recipe.ingredients) {
          if (ingredient.name.toLowerCase().contains(query)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // Apply cook time filter
    if (cookTime != null) {
      switch (cookTime!) {
        case CookTimeFilter.quick:
          filtered = filtered.where((recipe) => recipe.cookTime <= 30).toList();
          break;
        case CookTimeFilter.medium:
          filtered = filtered.where((recipe) => recipe.cookTime > 30 && recipe.cookTime <= 60).toList();
          break;
        case CookTimeFilter.long:
          filtered = filtered.where((recipe) => recipe.cookTime > 60).toList();
          break;
        case CookTimeFilter.all:
          // No filter
          break;
      }
    }

    // Apply ingredient count filters
    if (minIngredients != null) {
      filtered = filtered.where((recipe) => recipe.ingredients.length >= minIngredients!).toList();
    }
    if (maxIngredients != null) {
      filtered = filtered.where((recipe) => recipe.ingredients.length <= maxIngredients!).toList();
    }

    return filtered;
  }
}

/// Expiration status filter options
enum ExpirationFilter {
  all,
  expired,
  expiringSoon,
  normal,
}

/// Cook time filter options
enum CookTimeFilter {
  all,
  quick, // <= 30 minutes
  medium, // 31-60 minutes
  long, // > 60 minutes
}

/// Get all unique categories from pantry items
List<String> getPantryCategories(List<PantryItem> items) {
  final categories = items.map((item) => item.category).toSet().toList();
  categories.sort();
  return categories;
}

