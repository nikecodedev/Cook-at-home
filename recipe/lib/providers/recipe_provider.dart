import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/firestore/firestore_service.dart';
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

/// Validate image format by checking magic bytes (file signature)
bool _isValidImageFormat(Uint8List bytes) {
  if (bytes.length < 4) return false;
  
  // Check for JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return true;
  }
  
  // Check for PNG: 89 50 4E 47
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    return true;
  }
  
  // Check for GIF: 47 49 46 38
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
    return true;
  }
  
  // Check for WebP: RIFF...WEBP
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
    return true;
  }
  
  return false;
}

/// Provider for all recipes stream
final allRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllRecipes();
});

/// Provider for user recipes stream
final userRecipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserRecipes(userId);
});

/// Provider for recipe loading state
final recipeLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for recipe error message
final recipeErrorProvider = StateProvider<String?>((ref) => null);

/// Recipe controller for handling recipe operations
class RecipeController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  RecipeController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Add a new recipe
  /// imageData can be File (mobile) or Uint8List (web), or null for no image
  Future<String> addRecipe(Recipe recipe, {dynamic imageData}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();
    _ref.read(recipeErrorProvider.notifier).state = null;

    try {
      // Validate recipe before saving
      if (recipe.title.isEmpty) {
        throw Exception('El título de la receta no puede estar vacío');
      }
      if (recipe.ingredients.isEmpty) {
        throw Exception('La receta debe tener al menos un ingrediente');
      }
      if (recipe.instructions.isEmpty) {
        throw Exception('La receta debe tener al menos una instrucción');
      }

      // First add the recipe to Firestore to get/create the ID
      final recipeId = await _firestoreService.addRecipe(recipe);
      Logger.info('Recipe added to Firestore with ID: $recipeId', 'RecipeController');
      Logger.info('  Has image data: ${imageData != null}', 'RecipeController');
      if (imageData != null) {
        Logger.info('  Image data type: ${imageData.runtimeType}', 'RecipeController');
      }

      // If there's an image, upload it and update the recipe
      // If image upload fails, recipe is still saved (without image)
      if (imageData != null) {
        Logger.info('Starting image upload for recipe: $recipeId', 'RecipeController');
        try {
          // Validate image data before upload
          bool isValidImageData = false;
          if (imageData is File) {
            isValidImageData = await imageData.exists();
            if (!isValidImageData) {
              throw Exception('El archivo de imagen no existe');
            }
          } else if (imageData is Uint8List) {
            isValidImageData = imageData.isNotEmpty;
            if (!isValidImageData) {
              throw Exception('Los datos de la imagen están vacíos');
            }
            // Validate image format before upload
            Logger.info('Validating image format before upload. Image size: ${imageData.length} bytes', 'RecipeController');
            if (!_isValidImageFormat(imageData)) {
              Logger.error('Invalid image format detected. First bytes: ${imageData.take(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}', 'RecipeController');
              throw Exception('El formato de la imagen no es válido. Por favor selecciona una imagen JPEG, PNG, GIF o WebP válida.');
            }
            Logger.success('Image format validated successfully', 'RecipeController');
          } else {
            throw Exception('Tipo de datos de imagen inválido: ${imageData.runtimeType}');
          }

          if (!isValidImageData) {
            throw Exception('Datos de imagen inválidos o vacíos');
          }

          // Upload image with extended timeout (60 seconds)
          // uploadRecipeImage now returns String? (null if upload fails)
          final imageUrl = await _firestoreService
              .uploadRecipeImage(recipeId, imageData)
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () {
                  Logger.warning('Image upload timed out - recipe will be saved without image', 'RecipeController');
                  return null; // Return null on timeout instead of throwing
                },
              );
          
          if (imageUrl != null && imageUrl.isNotEmpty) {
            Logger.success('Image uploaded successfully: $imageUrl', 'RecipeController');
            
            // Update recipe with image URL
            final updatedRecipe = recipe.copyWith(id: recipeId, imageUrl: imageUrl);
            await _firestoreService.updateRecipe(updatedRecipe);
            Logger.success('Recipe updated with image URL', 'RecipeController');
          } else {
            // Image upload failed but recipe is saved - this is OK
            Logger.info('Recipe saved successfully without image (upload failed or skipped)', 'RecipeController');
          }
        } catch (uploadError, uploadStack) {
          // This catch block should rarely be hit now since uploadRecipeImage returns null instead of throwing
          Logger.error('Unexpected error during image upload', uploadError, uploadStack, 'RecipeController');
          
          // Don't fail the entire recipe creation if image upload fails
          // Recipe is already saved to Firestore, just without image
          Logger.warning(
            'Recipe saved successfully but image upload failed. Recipe ID: $recipeId. Error: $uploadError',
            'RecipeController',
          );
          
          // Recipe is saved and functional without the image - continue normally
        }
      } else {
        Logger.info('No image data provided - recipe saved without image', 'RecipeController');
      }

      // Always reset state to data(null) to stop loading spinner
      state = const AsyncValue.data(null);
      Logger.success('Recipe saved successfully. ID: $recipeId', 'RecipeController');
      return recipeId;
    } catch (e, stackTrace) {
      Logger.error('Failed to add recipe', e, stackTrace, 'RecipeController');
      state = AsyncValue.error(e, stackTrace);
      _ref.read(recipeErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Update an existing recipe
  /// imageData can be File (mobile) or Uint8List (web)
  Future<void> updateRecipe(
    Recipe recipe, {
    dynamic imageData,
    String? oldImageUrl,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    if (recipe.authorId != userId) {
      throw Exception('No estás autorizado para actualizar esta receta');
    }

    state = const AsyncValue.loading();
    _ref.read(recipeErrorProvider.notifier).state = null;

    try {
      // If there's a new image, upload it
      String? imageUrl = recipe.imageUrl;
      if (imageData != null) {
        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          try {
            await _firestoreService.deleteRecipeImage(oldImageUrl);
          } catch (e) {
            // Log but don't fail if image deletion fails
            Logger.error('Failed to delete old recipe image', e, null, 'RecipeController');
          }
        }
        // Upload new image (returns null if upload fails - recipe will keep old image or no image)
        final newImageUrl = await _firestoreService.uploadRecipeImage(recipe.id, imageData);
        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          imageUrl = newImageUrl;
        } else {
          // Upload failed - fall back to old image URL so we don't lose it
          imageUrl = oldImageUrl;
          Logger.warning('Image upload failed during recipe update - reverting to old image URL', 'RecipeController');
        }
      }

      // Update recipe with new image URL if changed
      final updatedRecipe = imageData != null
          ? recipe.copyWith(imageUrl: imageUrl, updatedAt: DateTime.now())
          : recipe.copyWith(updatedAt: DateTime.now());

      await _firestoreService.updateRecipe(updatedRecipe);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(recipeErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId, {String? imageUrl}) async {
    state = const AsyncValue.loading();
    _ref.read(recipeErrorProvider.notifier).state = null;

    try {
      // Delete image if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _firestoreService.deleteRecipeImage(imageUrl);
        } catch (e) {
          // Log but don't fail if image deletion fails
          Logger.error('Failed to delete recipe image', e, null, 'RecipeController');
        }
      }

      // Delete recipe
      await _firestoreService.deleteRecipe(recipeId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(recipeErrorProvider.notifier).state = e.toString();
      rethrow;
    }
  }
}

/// Provider for RecipeController
final recipeControllerProvider =
    StateNotifierProvider<RecipeController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RecipeController(firestoreService, ref);
});

