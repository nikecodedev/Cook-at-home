import 'package:cloud_firestore/cloud_firestore.dart';

/// Recipe ingredient model
class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  RecipeIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'RecipeIngredient(name: $name, quantity: $quantity, unit: $unit)';
  }
}

/// Recipe model representing a recipe in the app
class Recipe {
  final String id;
  final String title;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions; // Step-by-step instructions
  final int cookTime; // in minutes
  final String? source;
  final String authorId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.cookTime,
    this.source,
    required this.authorId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      ingredients: (data['ingredients'] as List<dynamic>?)
              ?.map((ing) => RecipeIngredient.fromMap(ing as Map<String, dynamic>))
              .toList() ??
          [],
      instructions: (data['instructions'] as List<dynamic>?)
              ?.map((inst) => inst.toString())
              .toList() ??
          [],
      cookTime: data['cookTime'] ?? 0,
      source: data['source'],
      authorId: data['authorId'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create Recipe from Map
  factory Recipe.fromMap(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      title: data['title'] ?? '',
      ingredients: (data['ingredients'] as List<dynamic>?)
              ?.map((ing) => RecipeIngredient.fromMap(ing as Map<String, dynamic>))
              .toList() ??
          [],
      instructions: (data['instructions'] as List<dynamic>?)
              ?.map((inst) => inst.toString())
              .toList() ??
          [],
      cookTime: data['cookTime'] ?? 0,
      source: data['source'],
      authorId: data['authorId'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert Recipe to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ingredients': ingredients.map((ing) => ing.toMap()).toList(),
      'instructions': instructions,
      'cookTime': cookTime,
      'source': source,
      'authorId': authorId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  Recipe copyWith({
    String? id,
    String? title,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? cookTime,
    String? source,
    String? authorId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookTime: cookTime ?? this.cookTime,
      source: source ?? this.source,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted cook time
  String get formattedCookTime {
    if (cookTime < 60) {
      return '$cookTime min';
    }
    final hours = cookTime ~/ 60;
    final minutes = cookTime % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h $minutes min';
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, ingredients: ${ingredients.length}, instructions: ${instructions.length}, cookTime: $cookTime)';
  }
}

