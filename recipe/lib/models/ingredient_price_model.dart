import 'package:cloud_firestore/cloud_firestore.dart';

/// Ingredient price model - stores average price per canonical ingredient
class IngredientPrice {
  final String id;
  final String canonicalIngredientId; // Reference to canonical ingredient
  final double averagePrice; // Average price per default unit
  final String priceUnit; // Unit for the price (e.g., 'grams', 'liters', 'pieces')
  final double? userOverridePrice; // User's manual override (optional)
  final DateTime updatedAt; // Last update timestamp
  final DateTime createdAt;

  IngredientPrice({
    required this.id,
    required this.canonicalIngredientId,
    required this.averagePrice,
    required this.priceUnit,
    this.userOverridePrice,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Get the effective price (user override if set, otherwise average)
  double get effectivePrice => userOverridePrice ?? averagePrice;

  /// Create IngredientPrice from Firestore document
  factory IngredientPrice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return IngredientPrice(
      id: doc.id,
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
      priceUnit: (data['priceUnit'] as String?) ?? 'pieces',
      userOverridePrice: data['userOverridePrice'] != null
          ? (data['userOverridePrice'] as num).toDouble()
          : null,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? 
                 (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(), // Support legacy field
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create IngredientPrice from Map
  factory IngredientPrice.fromMap(Map<String, dynamic> data, String id) {
    return IngredientPrice(
      id: id,
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
      priceUnit: (data['priceUnit'] as String?) ?? 'pieces',
      userOverridePrice: data['userOverridePrice'] != null
          ? (data['userOverridePrice'] as num).toDouble()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['lastUpdated'] is Timestamp
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.now()), // Support legacy field
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert IngredientPrice to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'canonicalIngredientId': canonicalIngredientId,
      'averagePrice': averagePrice,
      'priceUnit': priceUnit,
      'userOverridePrice': userOverridePrice,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  IngredientPrice copyWith({
    String? id,
    String? canonicalIngredientId,
    double? averagePrice,
    String? priceUnit,
    double? userOverridePrice,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return IngredientPrice(
      id: id ?? this.id,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      averagePrice: averagePrice ?? this.averagePrice,
      priceUnit: priceUnit ?? this.priceUnit,
      userOverridePrice: userOverridePrice ?? this.userOverridePrice,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'IngredientPrice(id: $id, canonicalIngredientId: $canonicalIngredientId, effectivePrice: $effectivePrice $priceUnit)';
  }
}



