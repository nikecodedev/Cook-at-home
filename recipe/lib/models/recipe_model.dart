import 'package:cloud_firestore/cloud_firestore.dart';

/// Recipe ingredient model
class RecipeIngredient {
  final String name;
  final String? canonicalIngredientId; // Phase 2: Reference to canonical ingredient
  final double quantity;
  final String unit;
  final String? amazonLink;
  final String? walmartLink;

  RecipeIngredient({
    required this.name,
    this.canonicalIngredientId,
    required this.quantity,
    required this.unit,
    this.amazonLink,
    this.walmartLink,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name'] ?? '',
      canonicalIngredientId: data['canonicalIngredientId'] as String?,
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      amazonLink: data['amazonLink'],
      walmartLink: data['walmartLink'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'canonicalIngredientId': canonicalIngredientId,
      'quantity': quantity,
      'unit': unit,
      // Only save links if they are non-null and non-empty
      if (amazonLink != null && amazonLink!.isNotEmpty) 'amazonLink': amazonLink,
      if (walmartLink != null && walmartLink!.isNotEmpty) 'walmartLink': walmartLink,
    };
  }

  RecipeIngredient copyWith({
    String? name,
    String? canonicalIngredientId,
    double? quantity,
    String? unit,
    String? amazonLink,
    String? walmartLink,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      amazonLink: amazonLink ?? this.amazonLink,
      walmartLink: walmartLink ?? this.walmartLink,
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
  // Phase 2: Yield and portion fields
  final double? yieldValue; // Total yield value
  final String? yieldUnit; // Yield unit (grams, liters, cups, pieces)
  final double? standardPortionSize; // Standard portion size in yield units
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
    this.yieldValue,
    this.yieldUnit,
    this.standardPortionSize,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle imageUrl: treat empty strings as null
    final imageUrlValue = data['imageUrl'];
    final imageUrl = (imageUrlValue is String && imageUrlValue.isNotEmpty) 
        ? imageUrlValue 
        : null;
    
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
      imageUrl: imageUrl,
      yieldValue: data['yieldValue'] != null ? (data['yieldValue'] as num).toDouble() : null,
      yieldUnit: data['yieldUnit'] as String?,
      standardPortionSize: data['standardPortionSize'] != null ? (data['standardPortionSize'] as num).toDouble() : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create Recipe from Map
  factory Recipe.fromMap(Map<String, dynamic> data, String id) {
    // Handle imageUrl: treat empty strings as null
    final imageUrlValue = data['imageUrl'];
    final imageUrl = (imageUrlValue is String && imageUrlValue.isNotEmpty) 
        ? imageUrlValue 
        : null;
    
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
      imageUrl: imageUrl,
      yieldValue: data['yieldValue'] != null ? (data['yieldValue'] as num).toDouble() : null,
      yieldUnit: data['yieldUnit'] as String?,
      standardPortionSize: data['standardPortionSize'] != null ? (data['standardPortionSize'] as num).toDouble() : null,
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
      'yieldValue': yieldValue,
      'yieldUnit': yieldUnit,
      'standardPortionSize': standardPortionSize,
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
    double? yieldValue,
    String? yieldUnit,
    double? standardPortionSize,
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
      yieldValue: yieldValue ?? this.yieldValue,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      standardPortionSize: standardPortionSize ?? this.standardPortionSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate number of servings based on yield and portion size
  int? get numberOfServings {
    if (yieldValue == null || standardPortionSize == null || standardPortionSize == 0) {
      return null;
    }
    return (yieldValue! / standardPortionSize!).round();
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

