import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../core/config/firebase_config.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/profile_model.dart';
import '../../models/pantry_item_model.dart';
import '../../models/recipe_model.dart';
import '../../models/shopping_list_model.dart';
import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/logger.dart';
import '../purchase_link_service.dart';

/// Service for managing user profiles in Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;



  /// Get user profile from Firestore
  /// Returns null if profile doesn't exist
  Future<ProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          return ProfileModel.fromFirestore(doc);
        } catch (e) {
          Logger.error('Failed to parse profile from Firestore', e, null, 'FirestoreService');
          // Return null on parsing error instead of crashing
          return null;
        }
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Create a new user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? location,
    String unitPreference = 'metric',
    int servingSize = 4,
    List<HouseholdMember> householdMembers = const [],
  }) async {
    try {
      final now = DateTime.now();
      final profileModel = ProfileModel(
        userId: userId,
        name: name,
        email: email,
        location: location,
        unitPreference: unitPreference,
        servingSize: servingSize,
        householdMembers: householdMembers,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .set(profileModel.toMap(), SetOptions(merge: false));

      Logger.success('User profile created: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to create user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? location,
    String? unitPreference,
    int? servingSize,
    List<HouseholdMember>? householdMembers,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) {
        updates['name'] = name;
      }
      if (email != null) {
        updates['email'] = email;
      }
      if (location != null) {
        updates['location'] = location;
      }
      if (unitPreference != null) {
        updates['unitPreference'] = unitPreference;
      }
      if (servingSize != null) {
        updates['servingSize'] = servingSize;
      }
      if (householdMembers != null) {
        updates['householdMembers'] =
            householdMembers.map((member) => member.toMap()).toList();
      }

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update(updates);

      Logger.success('User profile updated: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update user profile', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream user profile changes
  Stream<ProfileModel?> streamUserProfile(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return ProfileModel.fromFirestore(doc);
        } catch (e) {
          Logger.error('Failed to parse profile from Firestore', e, null, 'FirestoreService');
          // Return null on parsing error to prevent app crash
          return null;
        }
      }
      return null;
    }).handleError((error) {
      Logger.error('Error in profile stream', error, null, 'FirestoreService');
      return null;
    });
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      Logger.error('Failed to check user profile', e, null, 'FirestoreService');
      return false;
    }
  }

  /// Update user's FCM token
  Future<void> updateUserFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
      Logger.success('FCM token updated for user: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update FCM token', e, null, 'FirestoreService');
      rethrow;
    }
  }

  // ==================== PANTRY ITEMS METHODS ====================

  /// Get all pantry items for a user, sorted by expiration date
  Future<List<PantryItem>> getPantryItems(String userId) async {
    try {
      // Get all items (can't use orderBy with null values, so we'll sort in code)
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.pantryItems)
          .get();

      final items = snapshot.docs
          .map((doc) => PantryItem.fromFirestore(doc))
          .toList();

      // Sort: items with expiration dates first (ascending), then items without dates
      items.sort((a, b) {
        if (a.expirationDate == null && b.expirationDate == null) {
          return b.addedAt.compareTo(a.addedAt); // Newest first for items without dates
        }
        if (a.expirationDate == null) return 1; // Items without dates go to end
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      Logger.success('Retrieved ${items.length} pantry items for user: $userId', 'FirestoreService');
      return items;
    } catch (e) {
      Logger.error('Failed to get pantry items', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream pantry items for real-time updates
  Stream<List<PantryItem>> streamPantryItems(String userId) {
    // Get all items (can't use orderBy with null values, so we'll sort in code)
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.pantryItems)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            try {
              return PantryItem.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse pantry item', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<PantryItem>()
          .toList();

      // Sort: items with expiration dates first (ascending), then items without dates
      items.sort((a, b) {
        if (a.expirationDate == null && b.expirationDate == null) {
          return b.addedAt.compareTo(a.addedAt); // Newest first for items without dates
        }
        if (a.expirationDate == null) return 1; // Items without dates go to end
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      return items;
    }).handleError((error) {
      Logger.error('Error in pantry items stream', error, null, 'FirestoreService');
      return <PantryItem>[];
    });
  }

  /// Add a new pantry item
  Future<String> addPantryItem(String userId, PantryItem item) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.pantryItems)
          .add(item.toMap());

      Logger.success('Pantry item added: ${docRef.id}', 'FirestoreService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to add pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update an existing pantry item
  Future<void> updatePantryItem(String userId, PantryItem item) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.pantryItems)
          .doc(item.id)
          .update(item.toMap());

      Logger.success('Pantry item updated: ${item.id}', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete a pantry item
  Future<void> deletePantryItem(String userId, String itemId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.pantryItems)
          .doc(itemId)
          .delete();

      Logger.success('Pantry item deleted: $itemId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to delete pantry item', e, null, 'FirestoreService');
      rethrow;
    }
  }

  // ==================== RECIPE METHODS ====================

  /// Get all recipes from Firestore
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.recipes)
          .orderBy('createdAt', descending: true)
          .get();

      final recipes = snapshot.docs
          .map((doc) {
            try {
              return Recipe.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse recipe', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<Recipe>()
          .toList();

      Logger.success('Retrieved ${recipes.length} recipes', 'FirestoreService');
      return recipes;
    } catch (e) {
      Logger.error('Failed to get all recipes', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream all recipes for real-time updates
  Stream<List<Recipe>> streamAllRecipes() {
    return _firestore
        .collection(FirebaseCollections.recipes)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final recipes = snapshot.docs
          .map((doc) {
            try {
              return Recipe.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse recipe', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<Recipe>()
          .toList();
      return recipes;
    }).handleError((error) {
      Logger.error('Error in recipes stream', error, null, 'FirestoreService');
      return <Recipe>[];
    });
  }

  /// Get recipes by a specific user
  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.recipes)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final recipes = snapshot.docs
          .map((doc) {
            try {
              return Recipe.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse recipe', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<Recipe>()
          .toList();

      Logger.success('Retrieved ${recipes.length} recipes for user: $userId', 'FirestoreService');
      return recipes;
    } catch (e) {
      Logger.error('Failed to get user recipes', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream user recipes for real-time updates
  Stream<List<Recipe>> streamUserRecipes(String userId) {
    return _firestore
        .collection(FirebaseCollections.recipes)
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final recipes = snapshot.docs
          .map((doc) {
            try {
              return Recipe.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse recipe', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<Recipe>()
          .toList();
      // Sort by createdAt in descending order (newest first) in memory
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recipes;
    }).handleError((error) {
      Logger.error('Error in user recipes stream', error, null, 'FirestoreService');
      return <Recipe>[];
    });
  }

  /// Add a new recipe
  Future<String> addRecipe(Recipe recipe) async {
    try {
      // Use the recipe's ID if provided, otherwise let Firestore generate one
      final docRef = recipe.id.isNotEmpty
          ? _firestore.collection(FirebaseCollections.recipes).doc(recipe.id)
          : _firestore.collection(FirebaseCollections.recipes).doc();

      await docRef.set(recipe.copyWith(id: docRef.id).toMap());

      Logger.success('Recipe added: ${docRef.id}', 'FirestoreService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to add recipe', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _firestore
          .collection(FirebaseCollections.recipes)
          .doc(recipe.id)
          .update(recipe.toMap());

      Logger.success('Recipe updated: ${recipe.id}', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update recipe', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.recipes)
          .doc(recipeId)
          .delete();

      Logger.success('Recipe deleted: $recipeId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to delete recipe', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Upload recipe image to Firebase Storage
  /// Supports both File (mobile) and Uint8List (web)
  /// Returns null if image upload fails (recipe can still be saved without image)
  Future<String?> uploadRecipeImage(
    String recipeId,
    dynamic imageData, // File or Uint8List
  ) async {
    try {
      // Validate recipe ID
      if (recipeId.isEmpty) {
        throw Exception('El ID de la receta no puede estar vacío');
      }

      // Validate image data
      if (imageData == null) {
        throw Exception('Los datos de la imagen no pueden ser nulos');
      }

      // Check if Firebase Storage is available
      final storage = FirebaseConfig.storage;
      
      // Validate storage instance
      if (storage == null) {
        Logger.warning('Firebase Storage is not initialized - recipe will be saved without image', 'FirestoreService');
        return null; // Return null instead of throwing - recipe can be saved without image
      }
      
      // Test storage availability by checking bucket with timeout
      try {
        final bucket = await Future.value(storage.app.options.storageBucket)
            .timeout(const Duration(seconds: 2));
        if (bucket == null || bucket.isEmpty) {
          Logger.warning('Storage bucket not configured - recipe will be saved without image', 'FirestoreService');
          return null;
        }
        Logger.info('Storage bucket verified: $bucket', 'FirestoreService');
      } catch (e) {
        Logger.warning('Cannot access storage bucket - recipe will be saved without image: $e', 'FirestoreService');
        return null;
      }
      
      // Verify storage is accessible by checking if we can create a reference
      try {
        final testRef = storage.ref('test');
        if (testRef == null) {
          Logger.warning('Cannot create storage reference - recipe will be saved without image', 'FirestoreService');
          return null;
        }
      } catch (e) {
        Logger.warning('Storage reference creation failed - recipe will be saved without image: $e', 'FirestoreService');
        return null;
      }

      // Generate unique filename - ensure recipeId is valid
      final cleanRecipeId = recipeId.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      if (cleanRecipeId.isEmpty) {
        throw Exception('El ID de la receta no es válido después de la limpieza');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 6);
      final fileName = 'recipe_${cleanRecipeId}_$randomSuffix.jpg';
      
      // Build file path - ensure it's properly formatted
      final filePath = FirebaseStoragePaths.recipeImage(cleanRecipeId, fileName);

      // Validate path doesn't contain invalid characters
      if (filePath.contains('//') || filePath.startsWith('/') || filePath.endsWith('/')) {
        Logger.warning('Invalid storage path format detected: $filePath - recipe will be saved without image', 'FirestoreService');
        return null;
      }
      
      // Additional validation: ensure path is not too long (Firebase Storage limit)
      if (filePath.length > 768) {
        Logger.warning('Storage path too long: $filePath - recipe will be saved without image', 'FirestoreService');
        return null;
      }

      Logger.info('Starting image upload to Firebase Storage', 'FirestoreService');
      Logger.info('  Recipe ID: $recipeId', 'FirestoreService');
      Logger.info('  File path: $filePath', 'FirestoreService');
      Logger.info('  Storage bucket: ${storage.app.options.storageBucket}', 'FirestoreService');

      // Create storage reference with validation
      Reference storageRef;
      try {
        storageRef = storage.ref(filePath);
        
        // Validate reference was created successfully
        if (storageRef == null) {
          throw Exception('Error al crear la referencia de almacenamiento para la ruta: $filePath');
        }
        
        // Verify the reference is valid by checking its path
        final refPath = storageRef.fullPath;
        if (refPath.isEmpty) {
          throw Exception('La ruta de referencia de almacenamiento está vacía');
        }
        Logger.info('Storage reference created successfully: $refPath', 'FirestoreService');
      } catch (e) {
        Logger.error('Failed to create storage reference', e, null, 'FirestoreService');
        // If reference creation fails, return null instead of throwing
        return null;
      }
      
      UploadTask uploadTask;
      if (imageData is File) {
        // Mobile platform - use File directly
        Logger.info('Uploading image file (mobile): ${imageData.path}', 'FirestoreService');
        if (!await imageData.exists()) {
          throw Exception('El archivo de imagen no existe: ${imageData.path}');
        }
        final fileSize = await imageData.length();
        if (fileSize == 0) {
          throw Exception('El archivo de imagen está vacío: ${imageData.path}');
        }
        Logger.info('File size: $fileSize bytes', 'FirestoreService');
        
        uploadTask = storageRef.putFile(
          imageData,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=3600',
          ),
        );
      } else if (imageData is Uint8List) {
        // Web or mobile - use Uint8List directly
        Logger.info('Uploading image bytes: ${imageData.length} bytes', 'FirestoreService');
        if (imageData.isEmpty) {
          throw Exception('Los datos de la imagen están vacíos');
        }
        uploadTask = storageRef.putData(
          imageData,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=3600',
          ),
        );
      } else {
        throw Exception('Tipo de datos de imagen no soportado: ${imageData.runtimeType}');
      }

      // Wait for upload to complete with timeout
      Logger.info('Waiting for upload to complete...', 'FirestoreService');
      TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            Logger.warning('Image upload timed out after 60 seconds - recipe will be saved without image', 'FirestoreService');
            throw TimeoutException('La carga de la imagen expiró');
          },
        );
      } catch (e) {
        if (e is TimeoutException) {
          return null; // Return null on timeout instead of throwing
        }
        rethrow; // Re-throw other exceptions to be caught by outer catch
      }
      
      Logger.info('Upload completed, getting download URL...', 'FirestoreService');

      // Get download URL with timeout
      String imageUrl;
      try {
        imageUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            Logger.warning('Failed to get download URL: timeout - recipe will be saved without image', 'FirestoreService');
            throw TimeoutException('Error al obtener la URL de descarga');
          },
        );
      } catch (e) {
        if (e is TimeoutException) {
          return null; // Return null on timeout instead of throwing
        }
        rethrow; // Re-throw other exceptions
      }

      Logger.success('Recipe image uploaded successfully: $imageUrl', 'FirestoreService');
      return imageUrl;
    } catch (e, stackTrace) {
      Logger.error('Failed to upload recipe image to Firebase Storage', e, stackTrace, 'FirestoreService');
      
      // Don't throw - return null so recipe can still be saved without image
      // This ensures recipe saving never fails due to image upload issues
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('object-not-found') || 
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        Logger.warning(
          'Storage bucket not found - recipe will be saved without image. '
          'Please check Firebase Storage is enabled and bucket is configured.',
          'FirestoreService',
        );
        return null; // Return null instead of throwing
      }
      
      if (errorMessage.contains('permission') || 
          errorMessage.contains('unauthorized') || 
          errorMessage.contains('403')) {
        Logger.warning(
          'Storage permission denied - recipe will be saved without image. '
          'Please check Firebase Storage security rules.',
          'FirestoreService',
        );
        return null; // Return null instead of throwing
      }
      
      if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
        Logger.warning(
          'Network error during image upload - recipe will be saved without image.',
          'FirestoreService',
        );
        return null; // Return null instead of throwing
      }
      
      // For any other error, log but don't fail recipe saving
      Logger.warning(
        'Image upload failed but recipe will be saved without image: $e',
        'FirestoreService',
      );
      return null; // Always return null instead of throwing
    }
  }

  /// Delete recipe image from Firebase Storage
  Future<void> deleteRecipeImage(String imageUrl) async {
    try {
      final storage = FirebaseConfig.storage;
      
      // Firebase Storage provides a convenient method to get a reference from a download URL
      final ref = storage.refFromURL(imageUrl);
      await ref.delete();

      Logger.success('Recipe image deleted from Firebase Storage: $imageUrl', 'FirestoreService');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete recipe image from Firebase Storage', e, stackTrace, 'FirestoreService');
      // Don't throw - image deletion failure shouldn't break the recipe deletion
      Logger.warning('Continuing despite image deletion failure', 'FirestoreService');
    }
  }

  // ==================== SHOPPING LIST METHODS ====================

  /// Generate a shopping list from a recipe's missing ingredients
  /// Compares recipe ingredients with user's pantry items
  Future<String> generateShoppingList({
    required String userId,
    required Recipe recipe,
    required List<PantryItem> pantryItems,
  }) async {
    try {
      final now = DateTime.now();
      final listId = _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc()
          .id;

      // Normalize pantry item names for comparison
      final pantryNames = pantryItems
          .map((item) => _normalizeIngredientName(item.name))
          .toSet();

      // Find missing ingredients
      final missingIngredients = <RecipeIngredient>[];
      for (final ingredient in recipe.ingredients) {
        final normalizedName = _normalizeIngredientName(ingredient.name);
        bool found = false;

        // Check if ingredient exists in pantry
        for (final pantryName in pantryNames) {
          if (_ingredientNamesMatch(normalizedName, pantryName)) {
            found = true;
            break;
          }
        }

        if (!found) {
          missingIngredients.add(ingredient);
        }
      }

      if (missingIngredients.isEmpty) {
        throw Exception('¡Todos los ingredientes ya están en tu despensa!');
      }

      // Create shopping list document
      final shoppingList = {
        'name': recipe.title,
        'recipeId': recipe.id,
        'recipeTitle': recipe.title,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .set(shoppingList);

      // Add items to subcollection
      final batch = _firestore.batch();
      for (final ingredient in missingIngredients) {
        final itemId = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.shoppingLists)
            .doc(listId)
            .collection(FirebaseCollections.shoppingListItems)
            .doc()
            .id;

        // Generate search links for Amazon and Walmart
        final amazonLink = _generateAmazonLink(ingredient.name);
        final walmartLink = _generateWalmartLink(ingredient.name);

        final itemRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.shoppingLists)
            .doc(listId)
            .collection(FirebaseCollections.shoppingListItems)
            .doc(itemId);

        batch.set(itemRef, {
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'isChecked': false,
          'amazonLink': amazonLink,
          'walmartLink': walmartLink,
          'addedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();

      Logger.success(
        'Shopping list generated: $listId with ${missingIngredients.length} items',
        'FirestoreService',
      );
      return listId;
    } catch (e) {
      Logger.error('Failed to generate shopping list', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Get all shopping lists for a user
  Future<List<ShoppingList>> getShoppingLists(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .orderBy('createdAt', descending: true)
          .get();

      final lists = snapshot.docs
          .map((doc) => ShoppingList.fromFirestore(doc))
          .toList();

      Logger.success('Retrieved ${lists.length} shopping lists', 'FirestoreService');
      return lists;
    } catch (e) {
      Logger.error('Failed to get shopping lists', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream shopping lists for real-time updates
  Stream<List<ShoppingList>> streamShoppingLists(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.shoppingLists)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingList.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      Logger.error('Error in shopping lists stream', error, null, 'FirestoreService');
      return <ShoppingList>[];
    });
  }

  /// Get shopping list items
  Future<List<ShoppingListItem>> getShoppingListItems(
    String userId,
    String listId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .collection(FirebaseCollections.shoppingListItems)
          .orderBy('addedAt')
          .get();

      final items = snapshot.docs
          .map((doc) => ShoppingListItem.fromFirestore(doc))
          .toList();

      Logger.success(
        'Retrieved ${items.length} shopping list items',
        'FirestoreService',
      );
      return items;
    } catch (e) {
      Logger.error(
        'Failed to get shopping list items',
        e,
        null,
        'FirestoreService',
      );
      rethrow;
    }
  }

  /// Stream shopping list items for real-time updates
  Stream<List<ShoppingListItem>> streamShoppingListItems(
    String userId,
    String listId,
  ) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.shoppingLists)
        .doc(listId)
        .collection(FirebaseCollections.shoppingListItems)
        .orderBy('addedAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListItem.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      Logger.error(
        'Error in shopping list items stream',
        error,
        null,
        'FirestoreService',
      );
      return <ShoppingListItem>[];
    });
  }

  /// Update shopping item checked status
  Future<void> updateShoppingItemStatus({
    required String userId,
    required String listId,
    required String itemId,
    required bool isChecked,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .collection(FirebaseCollections.shoppingListItems)
          .doc(itemId)
          .update({
        'isChecked': isChecked,
      });

      // Update shopping list updatedAt
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Logger.success(
        'Shopping item status updated: $itemId -> $isChecked',
        'FirestoreService',
      );
    } catch (e) {
      Logger.error(
        'Failed to update shopping item status',
        e,
        null,
        'FirestoreService',
      );
      rethrow;
    }
  }

  /// Update shopping list item (name, quantity, unit, links)
  Future<void> updateShoppingItem({
    required String userId,
    required String listId,
    required String itemId,
    required String name,
    required double quantity,
    required String unit,
    String? amazonLink,
    String? walmartLink,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

      if (amazonLink != null) {
        updateData['amazonLink'] = amazonLink;
      }
      if (walmartLink != null) {
        updateData['walmartLink'] = walmartLink;
      }

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .collection(FirebaseCollections.shoppingListItems)
          .doc(itemId)
          .update(updateData);

      // Update shopping list updatedAt
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Logger.success(
        'Shopping item updated: $itemId',
        'FirestoreService',
      );
    } catch (e) {
      Logger.error(
        'Failed to update shopping item',
        e,
        null,
        'FirestoreService',
      );
      rethrow;
    }
  }

  /// Delete a shopping list item
  Future<void> deleteShoppingItem({
    required String userId,
    required String listId,
    required String itemId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .collection(FirebaseCollections.shoppingListItems)
          .doc(itemId)
          .delete();

      // Update shopping list updatedAt
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Logger.success(
        'Shopping item deleted: $itemId',
        'FirestoreService',
      );
    } catch (e) {
      Logger.error(
        'Failed to delete shopping item',
        e,
        null,
        'FirestoreService',
      );
      rethrow;
    }
  }

  /// Update shopping list name
  Future<void> updateShoppingList({
    required String userId,
    required String listId,
    required String name,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .update({
        'name': name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Logger.success('Shopping list updated: $listId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update shopping list', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete a shopping list
  Future<void> deleteShoppingList(String userId, String listId) async {
    try {
      // Delete all items first
      final itemsSnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .collection(FirebaseCollections.shoppingListItems)
          .get();

      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the list
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .doc(listId)
          .delete();

      Logger.success('Shopping list deleted: $listId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to delete shopping list', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Helper: Normalize ingredient name for comparison
  String _normalizeIngredientName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Helper: Check if two ingredient names match
  bool _ingredientNamesMatch(String name1, String name2) {
    final normalized1 = _normalizeIngredientName(name1);
    final normalized2 = _normalizeIngredientName(name2);

    if (normalized1 == normalized2) return true;

    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      final shorter = normalized1.length < normalized2.length ? normalized1 : normalized2;
      final longer = normalized1.length >= normalized2.length ? normalized1 : normalized2;
      if (shorter.length >= (longer.length * 0.7)) {
        return true;
      }
    }

    final singular1 = normalized1.replaceAll(RegExp(r's$'), '');
    final singular2 = normalized2.replaceAll(RegExp(r's$'), '');
    if (singular1 == singular2 && singular1.length > 2) return true;

    return false;
  }

  /// Generate Amazon search link for item
  /// Uses PurchaseLinkService for centralized link generation with affiliate support
  String _generateAmazonLink(String itemName) {
    return PurchaseLinkService.generateAmazonLink(itemName: itemName);
  }

  /// Generate Walmart search link for item
  /// Uses PurchaseLinkService for centralized link generation with affiliate support
  String _generateWalmartLink(String itemName) {
    return PurchaseLinkService.generateWalmartLink(itemName: itemName);
  }

  // ==================== FEEDBACK METHODS ====================

  /// Submit feedback
  Future<String> submitFeedback({
    required String userId,
    required String message,
    required FeedbackCategory category,
  }) async {
    try {
      final now = DateTime.now();
      final feedbackId = _firestore.collection(FirebaseCollections.feedback).doc().id;

      final feedback = {
        'userId': userId,
        'message': message.trim(),
        'category': category.name,
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection(FirebaseCollections.feedback)
          .doc(feedbackId)
          .set(feedback);

      Logger.success('Feedback submitted: $feedbackId', 'FirestoreService');
      return feedbackId;
    } catch (e) {
      Logger.error('Failed to submit feedback', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Get user's feedback history
  Future<List<Feedback>> getUserFeedback(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.feedback)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final feedbackList = snapshot.docs
          .map((doc) => Feedback.fromFirestore(doc))
          .toList();

      Logger.success('Retrieved ${feedbackList.length} feedback items', 'FirestoreService');
      return feedbackList;
    } catch (e) {
      Logger.error('Failed to get user feedback', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Stream user's feedback history
  Stream<List<Feedback>> streamUserFeedback(String userId) {
    return _firestore
        .collection(FirebaseCollections.feedback)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Feedback.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      Logger.error('Error in feedback stream', error, null, 'FirestoreService');
      return <Feedback>[];
    });
  }

  // ==================== ADMIN METHODS ====================

  /// Get all users (Admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return UserModel(
                userId: doc.id,
                email: data['email'] ?? '',
                displayName: data['displayName'] ?? data['name'] ?? '',
                photoURL: data['photoURL'],
                role: data['role'] ?? 'user',
                preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            } catch (e) {
              Logger.error('Failed to parse user: ${doc.id}', e, null, 'FirestoreService');
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();

      Logger.success('Retrieved ${users.length} users', 'FirestoreService');
      return users;
    } catch (e) {
      Logger.error('Failed to get all users', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Update user role (Admin only)
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'role': role,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      Logger.success('User role updated: $userId -> $role', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to update user role', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete user (Admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user's pantry items
      final pantrySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.pantryItems)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in pantrySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's shopping lists
      final shoppingListsSnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.shoppingLists)
          .get();
      
      for (final listDoc in shoppingListsSnapshot.docs) {
        // Delete shopping list items
        final itemsSnapshot = await listDoc.reference
            .collection(FirebaseCollections.shoppingListItems)
            .get();
        for (final itemDoc in itemsSnapshot.docs) {
          batch.delete(itemDoc.reference);
        }
        batch.delete(listDoc.reference);
      }

      // Delete user profile
      batch.delete(_firestore.collection(FirebaseCollections.users).doc(userId));

      await batch.commit();
      Logger.success('User deleted: $userId', 'FirestoreService');
    } catch (e) {
      Logger.error('Failed to delete user', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Delete any recipe (Admin only)
  Future<void> deleteRecipeAsAdmin(String recipeId) async {
    try {
      // Get recipe to check for image
      final recipeDoc = await _firestore
          .collection(FirebaseCollections.recipes)
          .doc(recipeId)
          .get();

      if (recipeDoc.exists) {
        final data = recipeDoc.data();
        final imageUrl = data?['imageUrl'] as String?;

        // Delete recipe image if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await deleteRecipeImage(imageUrl);
          } catch (e) {
            Logger.warning('Failed to delete recipe image: $e', 'FirestoreService');
          }
        }

        // Delete recipe document
        await _firestore
            .collection(FirebaseCollections.recipes)
            .doc(recipeId)
            .delete();

        Logger.success('Recipe deleted by admin: $recipeId', 'FirestoreService');
      }
    } catch (e) {
      Logger.error('Failed to delete recipe as admin', e, null, 'FirestoreService');
      rethrow;
    }
  }

  /// Get admin statistics
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection(FirebaseCollections.users).get();
      final recipesSnapshot = await _firestore.collection(FirebaseCollections.recipes).get();
      final feedbackSnapshot = await _firestore.collection(FirebaseCollections.feedback).get();

      // Count pantry items across all users
      int totalPantryItems = 0;
      for (final userDoc in usersSnapshot.docs) {
        final pantrySnapshot = await userDoc.reference
            .collection(FirebaseCollections.pantryItems)
            .get();
        totalPantryItems += pantrySnapshot.docs.length;
      }

      // Count shopping lists
      int totalShoppingLists = 0;
      for (final userDoc in usersSnapshot.docs) {
        final shoppingListsSnapshot = await userDoc.reference
            .collection(FirebaseCollections.shoppingLists)
            .get();
        totalShoppingLists += shoppingListsSnapshot.docs.length;
      }

      final stats = {
        'totalUsers': usersSnapshot.docs.length,
        'totalRecipes': recipesSnapshot.docs.length,
        'totalPantryItems': totalPantryItems,
        'totalShoppingLists': totalShoppingLists,
        'totalFeedback': feedbackSnapshot.docs.length,
        'adminUsers': usersSnapshot.docs
            .where((doc) => (doc.data()['role'] ?? 'user') == 'admin')
            .length,
      };

      Logger.success('Admin statistics retrieved', 'FirestoreService');
      return stats;
    } catch (e) {
      Logger.error('Failed to get admin statistics', e, null, 'FirestoreService');
      rethrow;
    }
  }
}

