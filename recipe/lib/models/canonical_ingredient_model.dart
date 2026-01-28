import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical ingredient model - represents a standardized ingredient
/// All pantry items, recipes, and shopping lists reference canonical ingredients
class CanonicalIngredient {
  final String id;
  final String name; // Primary name (normalized)
  final List<String> synonyms; // Alternative names and spellings
  final String? category; // Optional category
  final String? defaultUnit; // Suggested unit for this ingredient
  final DateTime createdAt;
  final DateTime updatedAt;

  CanonicalIngredient({
    required this.id,
    required this.name,
    this.synonyms = const [],
    this.category,
    this.defaultUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CanonicalIngredient from Firestore document
  factory CanonicalIngredient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CanonicalIngredient(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      synonyms: List<String>.from(data['synonyms'] ?? [])
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      category: data['category'] as String?,
      defaultUnit: data['defaultUnit'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create CanonicalIngredient from Map
  factory CanonicalIngredient.fromMap(Map<String, dynamic> data, String id) {
    return CanonicalIngredient(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      synonyms: List<String>.from(data['synonyms'] ?? [])
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      category: data['category'] as String?,
      defaultUnit: data['defaultUnit'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert CanonicalIngredient to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'synonyms': synonyms,
      'category': category,
      'defaultUnit': defaultUnit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  CanonicalIngredient copyWith({
    String? id,
    String? name,
    List<String>? synonyms,
    String? category,
    String? defaultUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanonicalIngredient(
      id: id ?? this.id,
      name: name ?? this.name,
      synonyms: synonyms ?? this.synonyms,
      category: category ?? this.category,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get all possible names (name + synonyms) for matching
  List<String> get allNames {
    return [name, ...synonyms];
  }

  /// Normalize a string for matching (lowercase, trim, remove accents)
  /// Removes diacritics (accents) from characters for better matching
  static String normalize(String input) {
    return _removeAccents(input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')); // Normalize whitespace
  }

  /// Remove accents/diacritics from a string
  /// Converts accented characters to their base form (e.g., é -> e, ñ -> n)
  static String _removeAccents(String input) {
    const Map<String, String> accentMap = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ñ': 'n', 'ç': 'c',
      'Á': 'a', 'À': 'a', 'Ä': 'a', 'Â': 'a', 'Ã': 'a', 'Å': 'a',
      'É': 'e', 'È': 'e', 'Ë': 'e', 'Ê': 'e',
      'Í': 'i', 'Ì': 'i', 'Ï': 'i', 'Î': 'i',
      'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ô': 'o', 'Õ': 'o',
      'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Û': 'u',
      'Ý': 'y',
      'Ñ': 'n', 'Ç': 'c',
    };
    
    String result = input;
    accentMap.forEach((accented, base) {
      result = result.replaceAll(accented, base);
    });
    return result;
  }

  /// Check if this ingredient matches a given name (case-insensitive, handles synonyms)
  bool matches(String ingredientName) {
    final normalized = normalize(ingredientName);
    return allNames.any((name) => normalize(name) == normalized);
  }

  @override
  String toString() {
    return 'CanonicalIngredient(id: $id, name: $name, synonyms: $synonyms)';
  }
}



