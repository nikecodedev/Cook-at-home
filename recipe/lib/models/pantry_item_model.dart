import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_store_model.dart';

/// Pantry item model representing an item in the user's pantry
class PantryItem {
  final String id;
  final String name;
  final String? canonicalIngredientId; // Phase 2: Reference to canonical ingredient
  final double quantity;
  final String unit;
  final String category;
  final DateTime? expirationDate;
  final DateTime addedAt;
  final String? amazonUrl;
  final String? walmartUrl;
  final List<CustomStoreLink> customStores; // User's custom store links
  final int usageCount; // Track how often this item is used

  PantryItem({
    required this.id,
    required this.name,
    this.canonicalIngredientId,
    required this.quantity,
    required this.unit,
    required this.category,
    this.expirationDate,
    required this.addedAt,
    this.amazonUrl,
    this.walmartUrl,
    this.customStores = const [],
    this.usageCount = 0,
  });

  /// Create PantryItem from Firestore document
  factory PantryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PantryItem(
      id: doc.id,
      name: data['name'] ?? '',
      canonicalIngredientId: data['canonicalIngredientId'] as String?,
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      category: data['category'] ?? '',
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amazonUrl: data['amazonUrl'] as String?,
      walmartUrl: data['walmartUrl'] as String?,
      customStores: (data['customStores'] as List<dynamic>?)
              ?.map((e) => CustomStoreLink.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageCount: (data['usageCount'] as int?) ?? 0,
    );
  }

  /// Create PantryItem from Map
  factory PantryItem.fromMap(Map<String, dynamic> data, String id) {
    return PantryItem(
      id: id,
      name: data['name'] ?? '',
      canonicalIngredientId: data['canonicalIngredientId'] as String?,
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      category: data['category'] ?? '',
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] is Timestamp
              ? (data['expirationDate'] as Timestamp).toDate()
              : DateTime.parse(data['expirationDate'].toString()))
          : null,
      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.parse(data['addedAt'].toString()),
      amazonUrl: data['amazonUrl'] as String?,
      walmartUrl: data['walmartUrl'] as String?,
      customStores: (data['customStores'] as List<dynamic>?)
              ?.map((e) => CustomStoreLink.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageCount: (data['usageCount'] as int?) ?? 0,
    );
  }

  /// Convert PantryItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'canonicalIngredientId': canonicalIngredientId,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expirationDate': expirationDate != null
          ? Timestamp.fromDate(expirationDate!)
          : null,
      'addedAt': Timestamp.fromDate(addedAt),
      'amazonUrl': amazonUrl,
      'walmartUrl': walmartUrl,
      'customStores': customStores.map((e) => e.toMap()).toList(),
      'usageCount': usageCount,
    };
  }

  /// Create a copy with updated fields
  PantryItem copyWith({
    String? id,
    String? name,
    String? canonicalIngredientId,
    double? quantity,
    String? unit,
    String? category,
    DateTime? expirationDate,
    DateTime? addedAt,
    String? amazonUrl,
    String? walmartUrl,
    List<CustomStoreLink>? customStores,
    int? usageCount,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expirationDate: expirationDate ?? this.expirationDate,
      addedAt: addedAt ?? this.addedAt,
      amazonUrl: amazonUrl ?? this.amazonUrl,
      walmartUrl: walmartUrl ?? this.walmartUrl,
      customStores: customStores ?? this.customStores,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Check if item is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  /// Check if item is expiring soon (within 3 days)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiration = expirationDate!.difference(now).inDays;
    return daysUntilExpiration >= 0 && daysUntilExpiration <= 3;
  }

  /// Get days until expiration (negative if expired)
  int get daysUntilExpiration {
    if (expirationDate == null) return 999; // No expiration date
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'PantryItem(id: $id, name: $name, quantity: $quantity $unit, category: $category, expirationDate: $expirationDate)';
  }
}

