import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/canonical_ingredient_model.dart';
import '../core/utils/logger.dart';

/// Service for managing canonical ingredients
class CanonicalIngredientService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Get a canonical ingredient by ID
  Future<CanonicalIngredient?> getCanonicalIngredient(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return CanonicalIngredient.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get canonical ingredient', e, null, 'CanonicalIngredientService');
      return null;
    }
  }

  /// Find a canonical ingredient by name (handles synonyms and normalization)
  Future<CanonicalIngredient?> findCanonicalIngredientByName(String ingredientName) async {
    try {
      final normalized = CanonicalIngredient.normalize(ingredientName);
      
      // First, try exact match on name field
      final nameQuery = await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .where('name', isEqualTo: normalized)
          .limit(1)
          .get();

      if (nameQuery.docs.isNotEmpty) {
        return CanonicalIngredient.fromFirestore(nameQuery.docs.first);
      }

      // If not found, search through all ingredients and check synonyms
      // Note: Firestore doesn't support array-contains with normalization,
      // so we need to fetch and filter in memory for synonyms
      final allIngredients = await getAllCanonicalIngredients();
      
      for (final ingredient in allIngredients) {
        if (ingredient.matches(ingredientName)) {
          return ingredient;
        }
      }

      return null;
    } catch (e) {
      Logger.error('Failed to find canonical ingredient by name', e, null, 'CanonicalIngredientService');
      return null;
    }
  }

  /// Get all canonical ingredients
  Future<List<CanonicalIngredient>> getAllCanonicalIngredients() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CanonicalIngredient.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get all canonical ingredients', e, null, 'CanonicalIngredientService');
      return [];
    }
  }

  /// Stream all canonical ingredients
  Stream<List<CanonicalIngredient>> streamAllCanonicalIngredients() {
    return _firestore
        .collection(FirebaseCollections.canonicalIngredients)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return CanonicalIngredient.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse canonical ingredient', e, null, 'CanonicalIngredientService');
              return null;
            }
          })
          .whereType<CanonicalIngredient>()
          .toList();
    }).handleError((error) {
      Logger.error('Error in canonical ingredients stream', error, null, 'CanonicalIngredientService');
      return <CanonicalIngredient>[];
    });
  }

  /// Create or get canonical ingredient
  /// Returns the ID of the created or existing ingredient
  Future<String> createOrGetCanonicalIngredient({
    required String name,
    List<String>? synonyms,
    String? category,
    String? defaultUnit,
  }) async {
    try {
      // Normalize the name
      final normalized = CanonicalIngredient.normalize(name);
      
      // Check if ingredient already exists
      final existing = await findCanonicalIngredientByName(name);
      if (existing != null) {
        // Update synonyms if new ones provided
        if (synonyms != null && synonyms.isNotEmpty) {
          final updatedSynonyms = [
            ...existing.synonyms,
            ...synonyms.map((s) => CanonicalIngredient.normalize(s)),
          ].toSet().toList(); // Remove duplicates
          
          await updateCanonicalIngredient(
            existing.id,
            synonyms: updatedSynonyms,
          );
        }
        return existing.id;
      }

      // Create new canonical ingredient
      final now = DateTime.now();
      final ingredient = CanonicalIngredient(
        id: '', // Will be set by Firestore
        name: normalized,
        synonyms: (synonyms ?? [])
            .map((s) => CanonicalIngredient.normalize(s))
            .where((s) => s.isNotEmpty && s != normalized)
            .toSet()
            .toList(),
        category: category,
        defaultUnit: defaultUnit,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .add(ingredient.toMap());

      Logger.success('Canonical ingredient created: ${docRef.id}', 'CanonicalIngredientService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create canonical ingredient', e, null, 'CanonicalIngredientService');
      rethrow;
    }
  }

  /// Update a canonical ingredient
  Future<void> updateCanonicalIngredient(
    String id, {
    String? name,
    List<String>? synonyms,
    String? category,
    String? defaultUnit,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) {
        updates['name'] = CanonicalIngredient.normalize(name);
      }
      if (synonyms != null) {
        updates['synonyms'] = synonyms
            .map((s) => CanonicalIngredient.normalize(s))
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      }
      if (category != null) {
        updates['category'] = category;
      }
      if (defaultUnit != null) {
        updates['defaultUnit'] = defaultUnit;
      }

      await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .doc(id)
          .update(updates);

      Logger.success('Canonical ingredient updated: $id', 'CanonicalIngredientService');
    } catch (e) {
      Logger.error('Failed to update canonical ingredient', e, null, 'CanonicalIngredientService');
      rethrow;
    }
  }

  /// Delete a canonical ingredient (use with caution)
  Future<void> deleteCanonicalIngredient(String id) async {
    try {
      await _firestore
          .collection(FirebaseCollections.canonicalIngredients)
          .doc(id)
          .delete();

      Logger.success('Canonical ingredient deleted: $id', 'CanonicalIngredientService');
    } catch (e) {
      Logger.error('Failed to delete canonical ingredient', e, null, 'CanonicalIngredientService');
      rethrow;
    }
  }
}



