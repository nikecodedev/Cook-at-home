import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/product_model.dart';
import '../core/utils/logger.dart';

/// Service for managing products (barcode-scannable items)
class ProductService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Get a product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final normalizedBarcode = barcode.trim();
      final snapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where(FirebaseFields.barcode, isEqualTo: normalizedBarcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Product.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get product by barcode', e, null, 'ProductService');
      return null;
    }
  }

  /// Get a product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.products)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get product by ID', e, null, 'ProductService');
      return null;
    }
  }

  /// Create a new product (contribute product flow)
  Future<String> createProduct({
    required String barcode,
    required String name,
    required String canonicalIngredientId,
    String? brand,
    String? category,
    String? suggestedUnit,
    String? imageUrl,
    String? contributorId,
  }) async {
    try {
      // Check if product with this barcode already exists
      final existing = await getProductByBarcode(barcode);
      if (existing != null) {
        Logger.warning('Product with barcode $barcode already exists', 'ProductService');
        return existing.id;
      }

      final now = DateTime.now();
      final product = Product(
        id: '', // Will be set by Firestore
        barcode: barcode.trim(),
        name: name.trim(),
        brand: brand?.trim(),
        category: category,
        suggestedUnit: suggestedUnit,
        imageUrl: imageUrl,
        canonicalIngredientId: canonicalIngredientId,
        contributorId: contributorId,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(FirebaseCollections.products)
          .add(product.toMap());

      Logger.success('Product created: ${docRef.id}', 'ProductService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create product', e, null, 'ProductService');
      rethrow;
    }
  }

  /// Update a product
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(FirebaseCollections.products)
          .doc(product.id)
          .update(product.copyWith(updatedAt: DateTime.now()).toMap());

      Logger.success('Product updated: ${product.id}', 'ProductService');
    } catch (e) {
      Logger.error('Failed to update product', e, null, 'ProductService');
      rethrow;
    }
  }

  /// Search products by name
  Future<List<Product>> searchProducts(String query) async {
    try {
      final normalizedQuery = query.trim().toLowerCase();
      
      // Firestore doesn't support full-text search, so we'll fetch and filter
      // For better performance, consider using Algolia or similar in production
      final snapshot = await _firestore
          .collection(FirebaseCollections.products)
          .limit(100) // Limit to prevent excessive reads
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) {
            final nameMatch = product.name.toLowerCase().contains(normalizedQuery);
            final brandMatch = product.brand?.toLowerCase().contains(normalizedQuery) ?? false;
            return nameMatch || brandMatch;
          })
          .toList();
    } catch (e) {
      Logger.error('Failed to search products', e, null, 'ProductService');
      return [];
    }
  }

  /// Get products by canonical ingredient ID
  Future<List<Product>> getProductsByCanonicalIngredient(String canonicalIngredientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where(FirebaseFields.canonicalIngredientId, isEqualTo: canonicalIngredientId)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get products by canonical ingredient', e, null, 'ProductService');
      return [];
    }
  }
}

