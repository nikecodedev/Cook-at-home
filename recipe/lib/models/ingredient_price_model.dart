import 'package:cloud_firestore/cloud_firestore.dart';

/// Pricing type for ingredients
/// - perUnit: price per single unit (e.g., 4 MXN per egg)
/// - perPackage: price per package (e.g., 49 MXN per pack of 8 buns)
/// - perWeight: price per weight/volume unit (e.g., 120 MXN per kg)
enum PricingType {
  perUnit,
  perPackage,
  perWeight;

  String get displayName {
    switch (this) {
      case PricingType.perUnit:
        return 'Por unidad';
      case PricingType.perPackage:
        return 'Por paquete';
      case PricingType.perWeight:
        return 'Por peso/volumen';
    }
  }

  String toJson() => name;

  static PricingType fromJson(String? value) {
    switch (value) {
      case 'perPackage':
        return PricingType.perPackage;
      case 'perWeight':
        return PricingType.perWeight;
      case 'perUnit':
      default:
        return PricingType.perUnit;
    }
  }
}

/// Ingredient price model - stores average price per canonical ingredient
class IngredientPrice {
  final String id;
  final String canonicalIngredientId; // Reference to canonical ingredient
  final double averagePrice; // Average price per default unit
  final String priceUnit; // Unit for the price (e.g., 'grams', 'liters', 'pieces')
  final double? userOverridePrice; // User's manual override (optional)
  final PricingType pricingType; // How the price is structured
  final double? packageSize; // Number of items in package (for perPackage type)
  final String? packageUnit; // Unit of items in package (e.g., 'pieces', 'grams')
  final DateTime updatedAt; // Last update timestamp
  final DateTime createdAt;

  IngredientPrice({
    required this.id,
    required this.canonicalIngredientId,
    required this.averagePrice,
    required this.priceUnit,
    this.userOverridePrice,
    this.pricingType = PricingType.perUnit,
    this.packageSize,
    this.packageUnit,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Get the effective price (user override if set, otherwise average)
  double get effectivePrice => userOverridePrice ?? averagePrice;

  /// Calculate the effective unit price considering pricing type
  /// For perPackage: returns price per single item (packagePrice / packageSize)
  double get effectiveUnitPrice {
    final price = effectivePrice;
    if (pricingType == PricingType.perPackage && packageSize != null && packageSize! > 0) {
      return price / packageSize!;
    }
    return price;
  }

  /// Calculate cost for a given quantity
  /// For perPackage: cost = packagePrice × (quantityUsed / packageSize)
  double calculateCost(double quantity) {
    final price = effectivePrice;
    switch (pricingType) {
      case PricingType.perPackage:
        if (packageSize != null && packageSize! > 0) {
          return price * (quantity / packageSize!);
        }
        return price * quantity;
      case PricingType.perUnit:
      case PricingType.perWeight:
        return price * quantity;
    }
  }

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
      pricingType: PricingType.fromJson(data['pricingType'] as String?),
      packageSize: data['packageSize'] != null ? (data['packageSize'] as num).toDouble() : null,
      packageUnit: data['packageUnit'] as String?,
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
      pricingType: PricingType.fromJson(data['pricingType'] as String?),
      packageSize: data['packageSize'] != null ? (data['packageSize'] as num).toDouble() : null,
      packageUnit: data['packageUnit'] as String?,
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
      'pricingType': pricingType.toJson(),
      'packageSize': packageSize,
      'packageUnit': packageUnit,
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
    PricingType? pricingType,
    double? packageSize,
    String? packageUnit,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return IngredientPrice(
      id: id ?? this.id,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      averagePrice: averagePrice ?? this.averagePrice,
      priceUnit: priceUnit ?? this.priceUnit,
      userOverridePrice: userOverridePrice ?? this.userOverridePrice,
      pricingType: pricingType ?? this.pricingType,
      packageSize: packageSize ?? this.packageSize,
      packageUnit: packageUnit ?? this.packageUnit,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'IngredientPrice(id: $id, canonicalIngredientId: $canonicalIngredientId, effectivePrice: $effectivePrice $priceUnit)';
  }
}



