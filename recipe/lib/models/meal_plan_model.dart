import 'package:cloud_firestore/cloud_firestore.dart';

/// Meal plan model - represents a weekly meal plan
class MealPlan {
  final String id;
  final String userId;
  final DateTime weekStartDate; // Start of the week (Monday)
  final Map<String, List<String>> dailyRecipes; // day -> [recipeIds]
  // day keys: 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.dailyRecipes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create MealPlan from Firestore document
  factory MealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create MealPlan from Map
  factory MealPlan.fromMap(Map<String, dynamic> data, String id) {
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
      'dailyRecipes': dailyRecipes,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyRecipes: dailyRecipes ?? this.dailyRecipes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get all recipe IDs in the meal plan
  List<String> get allRecipeIds {
    return dailyRecipes.values.expand((ids) => ids).toSet().toList();
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, userId: $userId, weekStartDate: $weekStartDate)';
  }
}

