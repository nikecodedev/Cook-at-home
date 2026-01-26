import 'package:cloud_firestore/cloud_firestore.dart';

/// Refill alert model - represents a smart refill alert for pantry items
class RefillAlert {
  final String id;
  final String userId;
  final String canonicalIngredientId;
  final String ingredientName; // Display name
  final String reason; // 'depletion' or 'price_index'
  final double? currentQuantity; // Current quantity in pantry (if available)
  final String? currentUnit;
  final double? priceIndex; // Internal price index (if reason is price_index)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? dismissedAt;

  RefillAlert({
    required this.id,
    required this.userId,
    required this.canonicalIngredientId,
    required this.ingredientName,
    required this.reason,
    this.currentQuantity,
    this.currentUnit,
    this.priceIndex,
    this.isActive = true,
    required this.createdAt,
    this.dismissedAt,
  });

  /// Create RefillAlert from Firestore document
  factory RefillAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RefillAlert(
      id: doc.id,
      userId: (data['userId'] as String?)?.trim() ?? '',
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      ingredientName: (data['ingredientName'] as String?)?.trim() ?? '',
      reason: (data['reason'] as String?) ?? 'depletion',
      currentQuantity: data['currentQuantity'] != null
          ? (data['currentQuantity'] as num).toDouble()
          : null,
      currentUnit: data['currentUnit'] as String?,
      priceIndex: data['priceIndex'] != null
          ? (data['priceIndex'] as num).toDouble()
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dismissedAt: data['dismissedAt'] != null
          ? (data['dismissedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create RefillAlert from Map
  factory RefillAlert.fromMap(Map<String, dynamic> data, String id) {
    return RefillAlert(
      id: id,
      userId: (data['userId'] as String?)?.trim() ?? '',
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      ingredientName: (data['ingredientName'] as String?)?.trim() ?? '',
      reason: (data['reason'] as String?) ?? 'depletion',
      currentQuantity: data['currentQuantity'] != null
          ? (data['currentQuantity'] as num).toDouble()
          : null,
      currentUnit: data['currentUnit'] as String?,
      priceIndex: data['priceIndex'] != null
          ? (data['priceIndex'] as num).toDouble()
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      dismissedAt: data['dismissedAt'] != null
          ? (data['dismissedAt'] is Timestamp
              ? (data['dismissedAt'] as Timestamp).toDate()
              : DateTime.parse(data['dismissedAt'].toString()))
          : null,
    );
  }

  /// Convert RefillAlert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'canonicalIngredientId': canonicalIngredientId,
      'ingredientName': ingredientName,
      'reason': reason,
      'currentQuantity': currentQuantity,
      'currentUnit': currentUnit,
      'priceIndex': priceIndex,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'dismissedAt': dismissedAt != null ? Timestamp.fromDate(dismissedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  RefillAlert copyWith({
    String? id,
    String? userId,
    String? canonicalIngredientId,
    String? ingredientName,
    String? reason,
    double? currentQuantity,
    String? currentUnit,
    double? priceIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? dismissedAt,
  }) {
    return RefillAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      reason: reason ?? this.reason,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      currentUnit: currentUnit ?? this.currentUnit,
      priceIndex: priceIndex ?? this.priceIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }

  @override
  String toString() {
    return 'RefillAlert(id: $id, ingredientName: $ingredientName, reason: $reason, isActive: $isActive)';
  }
}

