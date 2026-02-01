import '../../models/pantry_item_model.dart';
import '../../models/recipe_model.dart';
import '../../models/shopping_list_model.dart';

/// Sorting options for pantry items
enum PantrySortOption {
  expiringSoon,    // Items expiring soonest first
  mostUsed,        // Most frequently used items first
  recentlyAdded,   // Most recently added items first
  alphabetical,    // A-Z by name
  category,        // Grouped by category
}

/// Frequency filter options
enum FrequencyFilter {
  all,
  frequentlyUsed,  // usageCount >= 5
  occasionallyUsed, // usageCount 1-4
  neverUsed,       // usageCount == 0
}

/// Filter options for pantry items
class PantryFilter {
  final String? category;
  final ExpirationFilter? expirationStatus;
  final FrequencyFilter? frequencyFilter;
  final String? searchQuery;
  final PantrySortOption sortOption;
  final DateTime? addedAfter;  // Filter by date added
  final DateTime? addedBefore;

  PantryFilter({
    this.category,
    this.expirationStatus,
    this.frequencyFilter,
    this.searchQuery,
    this.sortOption = PantrySortOption.expiringSoon,
    this.addedAfter,
    this.addedBefore,
  });

  PantryFilter copyWith({
    String? category,
    ExpirationFilter? expirationStatus,
    FrequencyFilter? frequencyFilter,
    String? searchQuery,
    PantrySortOption? sortOption,
    DateTime? addedAfter,
    DateTime? addedBefore,
    bool clearCategory = false,
    bool clearFrequencyFilter = false,
  }) {
    return PantryFilter(
      category: clearCategory ? null : (category ?? this.category),
      expirationStatus: expirationStatus ?? this.expirationStatus,
      frequencyFilter: clearFrequencyFilter ? null : (frequencyFilter ?? this.frequencyFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      addedAfter: addedAfter ?? this.addedAfter,
      addedBefore: addedBefore ?? this.addedBefore,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        expirationStatus != null ||
        frequencyFilter != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        addedAfter != null ||
        addedBefore != null;
  }

  List<PantryItem> applyFilters(List<PantryItem> items) {
    var filtered = List<PantryItem>.from(items);

    // Apply search query (predictive search)
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase().trim();
      filtered = filtered.where((item) {
        // Match name starting with query (predictive)
        final nameMatch = item.name.toLowerCase().startsWith(query) ||
            item.name.toLowerCase().contains(query);
        final categoryMatch = item.category.toLowerCase().contains(query);
        return nameMatch || categoryMatch;
      }).toList();
      
      // Sort by relevance - items starting with query first
      filtered.sort((a, b) {
        final aStartsWith = a.name.toLowerCase().startsWith(query);
        final bStartsWith = b.name.toLowerCase().startsWith(query);
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        return 0;
      });
    }

    // Apply category filter
    if (category != null && category!.isNotEmpty) {
      filtered = filtered.where((item) => item.category == category).toList();
    }

    // Apply date filters
    if (addedAfter != null) {
      filtered = filtered.where((item) => item.addedAt.isAfter(addedAfter!)).toList();
    }
    if (addedBefore != null) {
      filtered = filtered.where((item) => item.addedAt.isBefore(addedBefore!)).toList();
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

    // Apply frequency filter
    if (frequencyFilter != null) {
      switch (frequencyFilter!) {
        case FrequencyFilter.frequentlyUsed:
          filtered = filtered.where((item) => item.usageCount >= 5).toList();
          break;
        case FrequencyFilter.occasionallyUsed:
          filtered = filtered.where((item) => item.usageCount >= 1 && item.usageCount < 5).toList();
          break;
        case FrequencyFilter.neverUsed:
          filtered = filtered.where((item) => item.usageCount == 0).toList();
          break;
        case FrequencyFilter.all:
          // No filter
          break;
      }
    }

    // Apply sorting (only if no search query, which has its own relevance sorting)
    if (searchQuery == null || searchQuery!.isEmpty) {
      filtered = _applySorting(filtered);
    }

    return filtered;
  }

  List<PantryItem> _applySorting(List<PantryItem> items) {
    switch (sortOption) {
      case PantrySortOption.expiringSoon:
        items.sort((a, b) {
          // Items with expiration dates first, sorted by earliest expiration
          if (a.expirationDate == null && b.expirationDate == null) {
            return a.name.compareTo(b.name);
          }
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return a.expirationDate!.compareTo(b.expirationDate!);
        });
        break;
      case PantrySortOption.mostUsed:
        items.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case PantrySortOption.recentlyAdded:
        items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case PantrySortOption.alphabetical:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case PantrySortOption.category:
        items.sort((a, b) {
          final categoryCompare = a.category.compareTo(b.category);
          if (categoryCompare != 0) return categoryCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }
    return items;
  }
}

/// Sorting options for shopping lists
enum ShoppingListSortOption {
  recentFirst,     // Most recent first (default)
  oldestFirst,     // Oldest first
  alphabetical,    // A-Z by name
  byRecipe,        // Grouped by recipe
}

/// Archive filter mode for shopping lists
enum ArchiveFilterMode {
  active,    // Show only active (not archived) lists
  archived,  // Show only archived lists
  all,       // Show all lists
}

/// Grouping options for shopping lists
enum ShoppingListGroupOption {
  none,      // No grouping
  byWeek,    // Group by week
  byRecipe,  // Group by recipe
}

/// Filter options for shopping lists
class ShoppingListFilter {
  final String? searchQuery;
  final ShoppingListSortOption sortOption;
  final ArchiveFilterMode archiveMode;
  final String? recipeId;
  final String? source; // 'recipe', 'meal_plan', or null for all
  final ShoppingListGroupOption groupOption;

  ShoppingListFilter({
    this.searchQuery,
    this.sortOption = ShoppingListSortOption.recentFirst,
    this.archiveMode = ArchiveFilterMode.active,
    this.recipeId,
    this.source,
    this.groupOption = ShoppingListGroupOption.none,
  });

  // Legacy getter for backwards compatibility
  bool get showArchived => archiveMode != ArchiveFilterMode.active;

  ShoppingListFilter copyWith({
    String? searchQuery,
    ShoppingListSortOption? sortOption,
    ArchiveFilterMode? archiveMode,
    String? recipeId,
    String? source,
    ShoppingListGroupOption? groupOption,
  }) {
    return ShoppingListFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      archiveMode: archiveMode ?? this.archiveMode,
      recipeId: recipeId ?? this.recipeId,
      source: source ?? this.source,
      groupOption: groupOption ?? this.groupOption,
    );
  }

  bool get hasActiveFilters {
    return (searchQuery != null && searchQuery!.isNotEmpty) ||
        archiveMode != ArchiveFilterMode.active ||
        recipeId != null ||
        source != null;
  }

  List<ShoppingList> applyFilters(List<ShoppingList> lists) {
    var filtered = List<ShoppingList>.from(lists);

    // Filter by archive mode
    switch (archiveMode) {
      case ArchiveFilterMode.active:
        filtered = filtered.where((list) => !list.isArchived).toList();
        break;
      case ArchiveFilterMode.archived:
        filtered = filtered.where((list) => list.isArchived).toList();
        break;
      case ArchiveFilterMode.all:
        // Show all lists, no filtering
        break;
    }

    // Apply search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase().trim();
      filtered = filtered.where((list) {
        return list.name.toLowerCase().contains(query) ||
            (list.recipeTitle?.toLowerCase().contains(query) ?? false) ||
            (list.weekLabel?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by recipe
    if (recipeId != null) {
      filtered = filtered.where((list) => list.recipeId == recipeId).toList();
    }

    // Filter by source
    if (source != null) {
      filtered = filtered.where((list) => list.source == source).toList();
    }

    // Apply sorting
    filtered = _applySorting(filtered);

    return filtered;
  }

  List<ShoppingList> _applySorting(List<ShoppingList> lists) {
    switch (sortOption) {
      case ShoppingListSortOption.recentFirst:
        lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ShoppingListSortOption.oldestFirst:
        lists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ShoppingListSortOption.alphabetical:
        lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ShoppingListSortOption.byRecipe:
        lists.sort((a, b) {
          final recipeCompare = (a.recipeTitle ?? '').compareTo(b.recipeTitle ?? '');
          if (recipeCompare != 0) return recipeCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    return lists;
  }

  /// Group lists by week
  Map<String, List<ShoppingList>> groupByWeek(List<ShoppingList> lists) {
    final grouped = <String, List<ShoppingList>>{};
    
    for (final list in lists) {
      final weekLabel = list.weekLabel ?? _getWeekLabel(list.createdAt);
      if (!grouped.containsKey(weekLabel)) {
        grouped[weekLabel] = [];
      }
      grouped[weekLabel]!.add(list);
    }
    
    return grouped;
  }

  /// Group lists by recipe
  Map<String, List<ShoppingList>> groupByRecipe(List<ShoppingList> lists) {
    final grouped = <String, List<ShoppingList>>{};
    
    for (final list in lists) {
      final recipeKey = list.recipeTitle ?? 'Sin receta';
      if (!grouped.containsKey(recipeKey)) {
        grouped[recipeKey] = [];
      }
      grouped[recipeKey]!.add(list);
    }
    
    return grouped;
  }

  String _getWeekLabel(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final difference = startOfWeek.difference(date.subtract(Duration(days: date.weekday - 1))).inDays;
    
    if (difference == 0) {
      return 'Esta semana';
    } else if (difference == 7) {
      return 'Semana pasada';
    } else if (difference <= 28) {
      return 'Hace ${(difference / 7).ceil()} semanas';
    } else {
      final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      return '${months[date.month - 1]} ${date.year}';
    }
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

