import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model - represents a barcode-scannable product in the global catalog
class Product {
  final String id;
  final String barcode; // EAN/UPC barcode
  final String name; // Product name
  final String? brand; // Optional brand
  final String? category; // Optional category
  final String? suggestedUnit; // Suggested unit for this product
  final double? packageContent; // Package content amount (e.g., 500 for 500g)
  final String? packageUnit; // Package content unit (e.g., 'g', 'ml', 'pcs')
  final String? imageUrl; // Optional product photo
  final String canonicalIngredientId; // Maps to canonical ingredient
  final String? contributorId; // User who contributed this product
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.category,
    this.suggestedUnit,
    this.packageContent,
    this.packageUnit,
    this.imageUrl,
    required this.canonicalIngredientId,
    this.contributorId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get formatted package content string (e.g., "500 g", "1 L", "12 pcs")
  String? get formattedPackageContent {
    if (packageContent == null || packageUnit == null) return null;
    final contentStr = packageContent! % 1 == 0 
        ? packageContent!.toInt().toString() 
        : packageContent!.toString();
    return '$contentStr $packageUnit';
  }

  /// Create Product from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product(
      id: doc.id,
      barcode: (data['barcode'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? '',
      brand: data['brand'] as String?,
      category: data['category'] as String?,
      suggestedUnit: data['suggestedUnit'] as String?,
      packageContent: (data['packageContent'] as num?)?.toDouble(),
      packageUnit: data['packageUnit'] as String?,
      imageUrl: data['imageUrl'] as String?,
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      contributorId: data['contributorId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create Product from Map
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      barcode: (data['barcode'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? '',
      brand: data['brand'] as String?,
      category: data['category'] as String?,
      suggestedUnit: data['suggestedUnit'] as String?,
      packageContent: (data['packageContent'] as num?)?.toDouble(),
      packageUnit: data['packageUnit'] as String?,
      imageUrl: data['imageUrl'] as String?,
      canonicalIngredientId: (data['canonicalIngredientId'] as String?)?.trim() ?? '',
      contributorId: data['contributorId'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'suggestedUnit': suggestedUnit,
      'packageContent': packageContent,
      'packageUnit': packageUnit,
      'imageUrl': imageUrl,
      'canonicalIngredientId': canonicalIngredientId,
      'contributorId': contributorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    String? category,
    String? suggestedUnit,
    double? packageContent,
    String? packageUnit,
    String? imageUrl,
    String? canonicalIngredientId,
    String? contributorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      suggestedUnit: suggestedUnit ?? this.suggestedUnit,
      packageContent: packageContent ?? this.packageContent,
      packageUnit: packageUnit ?? this.packageUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      canonicalIngredientId: canonicalIngredientId ?? this.canonicalIngredientId,
      contributorId: contributorId ?? this.contributorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, barcode: $barcode, name: $name, canonicalIngredientId: $canonicalIngredientId)';
  }
}



