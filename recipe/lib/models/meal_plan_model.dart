import 'package:cloud_firestore/cloud_firestore.dart';

/// Meal plan model - represents a weekly meal plan
class MealPlan {
  final String id;
  final String userId;
  final DateTime weekStartDate; // Start of the week (Monday)
  final Map<String, List<String>> dailyRecipes; // day -> [recipeIds] (backward compatibility)
  // day keys: 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  final Map<String, Map<String, String?>> dailyMeals; // day -> mealType -> recipeId
  // mealType keys: 'breakfast', 'lunch', 'dinner'
  // day keys: 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.dailyRecipes,
    Map<String, Map<String, String?>>? dailyMeals,
    required this.createdAt,
    required this.updatedAt,
  }) : dailyMeals = dailyMeals ?? {};

  /// Get recipe ID for a specific day and meal type
  String? getRecipeForMeal(String dayKey, String mealType) {
    return dailyMeals[dayKey]?[mealType];
  }

  /// Set recipe for a specific day and meal type
  MealPlan setRecipeForMeal(String dayKey, String mealType, String? recipeId) {
    final updatedMeals = Map<String, Map<String, String?>>.from(dailyMeals);
    if (!updatedMeals.containsKey(dayKey)) {
      updatedMeals[dayKey] = {};
    }
    updatedMeals[dayKey]![mealType] = recipeId;
    return copyWith(dailyMeals: updatedMeals);
  }

  /// Get all unique recipe IDs from meal slots (includes backward compatibility with dailyRecipes)
  List<String> get allRecipeIds {
    final recipeIds = <String>{};

    // Get from meal slots
    for (final dayMeals in dailyMeals.values) {
      for (final recipeId in dayMeals.values) {
        if (recipeId != null && recipeId.isNotEmpty) {
          recipeIds.add(recipeId);
        }
      }
    }

    // Get from legacy dailyRecipes (backward compatibility)
    for (final recipeList in dailyRecipes.values) {
      recipeIds.addAll(recipeList);
    }

    return recipeIds.toList();
  }

  /// Get recipe IDs with their occurrence count (how many times each recipe appears)
  /// Used for shopping list scaling: if a recipe appears 3 times, multiply quantities by 3
  Map<String, int> get recipeIdCounts {
    final counts = <String, int>{};

    // Count from meal slots
    for (final dayMeals in dailyMeals.values) {
      for (final recipeId in dayMeals.values) {
        if (recipeId != null && recipeId.isNotEmpty) {
          counts[recipeId] = (counts[recipeId] ?? 0) + 1;
        }
      }
    }

    // Count from legacy dailyRecipes (backward compatibility)
    for (final recipeList in dailyRecipes.values) {
      for (final recipeId in recipeList) {
        if (recipeId.isNotEmpty) {
          counts[recipeId] = (counts[recipeId] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  /// Create MealPlan from Firestore document
  factory MealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse dailyMeals (new structure)
    final dailyMealsData = data['dailyMeals'] as Map<String, dynamic>? ?? {};
    final dailyMeals = <String, Map<String, String?>>{};
    for (final entry in dailyMealsData.entries) {
      final dayKey = entry.key;
      final mealsData = entry.value as Map<String, dynamic>? ?? {};
      dailyMeals[dayKey] = {
        'breakfast': mealsData['breakfast'] as String?,
        'lunch': mealsData['lunch'] as String?,
        'dinner': mealsData['dinner'] as String?,
      };
    }
    
    return MealPlan(
      id: doc.id,
      userId: (data['userId'] as String?)?.trim() ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dailyRecipes: Map<String, List<String>>.from(
        (data['dailyRecipes'] as Map<String, dynamic>?) ?? {},
      ).map((key, value) => MapEntry(
            key,
            List<String>.from(value as List<dynamic>? ?? []),
          )),
      dailyMeals: dailyMeals,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create MealPlan from Map
  factory MealPlan.fromMap(Map<String, dynamic> data, String id) {
    // Parse dailyMeals
    final dailyMealsData = data['dailyMeals'] as Map<String, dynamic>? ?? {};
    final dailyMeals = <String, Map<String, String?>>{};
    for (final entry in dailyMealsData.entries) {
      final dayKey = entry.key;
      final mealsData = entry.value is Map ? entry.value as Map<String, dynamic> : {};
      dailyMeals[dayKey] = {
        'breakfast': mealsData['breakfast'] as String?,
        'lunch': mealsData['lunch'] as String?,
        'dinner': mealsData['dinner'] as String?,
      };
    }
    
    return MealPlan(
      id: id,
      userId: (data['userId'] as String?)?.trim() ?? '',
      weekStartDate: data['weekStartDate'] is Timestamp
          ? (data['weekStartDate'] as Timestamp).toDate()
          : DateTime.now(),
      dailyRecipes: Map<String, List<String>>.from(
        (data['dailyRecipes'] as Map<String, dynamic>?) ?? {},
      ).map((key, value) => MapEntry(
            key,
            List<String>.from(value as List<dynamic>? ?? []),
          )),
      dailyMeals: dailyMeals,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert MealPlan to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'dailyRecipes': dailyRecipes, // Keep for backward compatibility
      'dailyMeals': dailyMeals.map((key, value) => MapEntry(key, value)),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  MealPlan copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    Map<String, List<String>>? dailyRecipes,
    Map<String, Map<String, String?>>? dailyMeals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyRecipes: dailyRecipes ?? this.dailyRecipes,
      dailyMeals: dailyMeals ?? this.dailyMeals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, userId: $userId, weekStartDate: $weekStartDate)';
  }
}



