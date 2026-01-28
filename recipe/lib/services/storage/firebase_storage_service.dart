import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/utils/logger.dart';

/// Firebase Storage Service
/// Handles all image uploads and deletions to Firebase Storage
class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  /// Get Firebase Storage instance
  FirebaseStorage get _storage => FirebaseConfig.storage;

  /// Upload an image to Firebase Storage
  /// 
  /// [path] - Storage path (e.g., 'recipes/recipeId/image.jpg')
  /// [imageData] - File (mobile) or Uint8List (web)
  /// [contentType] - MIME type (default: 'image/jpeg')
  /// [maxSizeMB] - Maximum file size in MB (default: 10MB)
  /// 
  /// Returns download URL on success, null on failure
  Future<String?> uploadImage({
    required String path,
    required dynamic imageData, // File or Uint8List
    String contentType = 'image/jpeg',
    double maxSizeMB = 10.0,
  }) async {
    try {
      // Validate path
      if (path.isEmpty) {
        throw Exception('El path de almacenamiento no puede estar vacío');
      }

      // Validate image data
      if (imageData == null) {
        throw Exception('Los datos de la imagen no pueden ser nulos');
      }

      // Check if Firebase Storage is available
      if (_storage == null) {
        Logger.warning('Firebase Storage is not initialized', 'FirebaseStorageService');
        return null;
      }

      // Validate storage bucket
      try {
        final bucket = _storage.app.options.storageBucket;
        if (bucket == null || bucket.isEmpty) {
          Logger.warning('Storage bucket not configured', 'FirebaseStorageService');
          return null;
        }
        Logger.info('Storage bucket verified: $bucket', 'FirebaseStorageService');
      } catch (e) {
        Logger.warning('Cannot access storage bucket: $e', 'FirebaseStorageService');
        return null;
      }

      // Validate and get file size
      int fileSize = 0;
      if (imageData is File) {
        if (!await imageData.exists()) {
          throw Exception('El archivo de imagen no existe: ${imageData.path}');
        }
        fileSize = await imageData.length();
        if (fileSize == 0) {
          throw Exception('El archivo de imagen está vacío: ${imageData.path}');
        }
      } else if (imageData is Uint8List) {
        if (imageData.isEmpty) {
          throw Exception('Los datos de la imagen están vacíos');
        }
        fileSize = imageData.length;
        
        // Validate image format by checking magic bytes (file signature)
        if (!_isValidImageFormat(imageData)) {
          Logger.error('Invalid image format detected. Bytes may be corrupted. Image will not be uploaded.', 'FirebaseStorageService');
          throw Exception('El formato de la imagen no es válido. Por favor selecciona una imagen JPEG, PNG, GIF o WebP válida.');
        }
      } else {
        throw Exception('Tipo de datos de imagen no soportado: ${imageData.runtimeType}');
      }

      // Check file size limit
      final maxSizeBytes = (maxSizeMB * 1024 * 1024).toInt();
      if (fileSize > maxSizeBytes) {
        throw Exception('El archivo es demasiado grande. Máximo: ${maxSizeMB}MB');
      }

      // Clean path
      final cleanPath = _cleanPath(path);
      if (cleanPath.isEmpty) {
        throw Exception('El path de almacenamiento no es válido después de la limpieza');
      }

      // Validate path length (Firebase Storage limit: 768 characters)
      if (cleanPath.length > 768) {
        Logger.warning('Storage path too long: $cleanPath', 'FirebaseStorageService');
        return null;
      }

      Logger.info('Starting image upload', 'FirebaseStorageService');
      Logger.info('  Path: $cleanPath', 'FirebaseStorageService');
      Logger.info('  File size: ${(fileSize / 1024).toStringAsFixed(2)} KB', 'FirebaseStorageService');

      // Create storage reference
      final storageRef = _storage.ref(cleanPath);

      // Upload based on platform
      UploadTask uploadTask;
      if (imageData is File) {
        Logger.info('Uploading image file (mobile): ${imageData.path}', 'FirebaseStorageService');
        uploadTask = storageRef.putFile(
          imageData,
          SettableMetadata(
            contentType: contentType,
            cacheControl: 'public, max-age=3600',
          ),
        );
      } else {
        Logger.info('Uploading image bytes: ${fileSize} bytes', 'FirebaseStorageService');
        
        // Final validation right before upload - ensure bytes are still valid
        final imageBytes = imageData as Uint8List;
        final firstBytes = imageBytes.take(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        Logger.info('Image first bytes (hex): $firstBytes', 'FirebaseStorageService');
        
        // Double-check format is still valid right before upload
        if (!_isValidImageFormat(imageBytes)) {
          Logger.error('Image format invalid right before upload! Bytes may have been corrupted.', 'FirebaseStorageService');
          throw Exception('El formato de la imagen no es válido. Los datos pueden haberse corrompido.');
        }
        
        // Create a copy of the bytes to ensure we're uploading fresh data
        // This helps prevent any potential issues with shared references
        final bytesToUpload = Uint8List.fromList(imageBytes);
        
        Logger.info('Uploading ${bytesToUpload.length} bytes to Firebase Storage', 'FirebaseStorageService');
        uploadTask = storageRef.putData(
          bytesToUpload,
          SettableMetadata(
            contentType: contentType,
            cacheControl: 'public, max-age=3600',
          ),
        );
      }

      // Wait for upload to complete with timeout
      Logger.info('Waiting for upload to complete...', 'FirebaseStorageService');
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          Logger.warning('Image upload timed out after 60 seconds', 'FirebaseStorageService');
          throw TimeoutException('La carga de la imagen expiró');
        },
      );

      Logger.info('Upload completed, getting download URL...', 'FirebaseStorageService');

      // Get download URL with timeout
      final imageUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Logger.warning('Failed to get download URL: timeout', 'FirebaseStorageService');
          throw TimeoutException('Error al obtener la URL de descarga');
        },
      );

      Logger.success('Image uploaded successfully: $imageUrl', 'FirebaseStorageService');
      return imageUrl;
    } catch (e, stackTrace) {
      Logger.error('Failed to upload image to Firebase Storage', e, stackTrace, 'FirebaseStorageService');

      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('object-not-found') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        Logger.warning(
          'Storage bucket not found. Please check Firebase Storage is enabled and bucket is configured.',
          'FirebaseStorageService',
        );
        return null;
      }

      if (errorMessage.contains('permission') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        Logger.warning(
          'Storage permission denied. Please check Firebase Storage security rules.',
          'FirebaseStorageService',
        );
        return null;
      }

      if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
        Logger.warning('Network error during image upload', 'FirebaseStorageService');
        return null;
      }

      // For other errors, return null (don't throw)
      Logger.warning('Image upload failed: $e', 'FirebaseStorageService');
      return null;
    }
  }

  /// Upload recipe image
  /// 
  /// [recipeId] - Recipe ID
  /// [imageData] - File (mobile) or Uint8List (web)
  /// 
  /// Returns download URL on success, null on failure
  Future<String?> uploadRecipeImage(
    String recipeId,
    dynamic imageData,
  ) async {
    try {
      // Generate unique filename
      final cleanRecipeId = recipeId.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      if (cleanRecipeId.isEmpty) {
        throw Exception('El ID de la receta no es válido');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 6);
      final fileName = 'recipe_${cleanRecipeId}_$randomSuffix.jpg';

      // Build file path
      final filePath = FirebaseStoragePaths.recipeImage(cleanRecipeId, fileName);

      return await uploadImage(
        path: filePath,
        imageData: imageData,
        contentType: 'image/jpeg',
        maxSizeMB: 10.0,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to upload recipe image', e, stackTrace, 'FirebaseStorageService');
      return null;
    }
  }

  /// Upload user profile image
  /// 
  /// [userId] - User ID
  /// [imageData] - File (mobile) or Uint8List (web)
  /// 
  /// Returns download URL on success, null on failure
  Future<String?> uploadUserProfileImage(
    String userId,
    dynamic imageData,
  ) async {
    try {
      // Generate unique filename
      final cleanUserId = userId.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      if (cleanUserId.isEmpty) {
        throw Exception('El ID del usuario no es válido');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 6);
      final fileName = 'profile_${cleanUserId}_$randomSuffix.jpg';

      // Build file path
      final filePath = FirebaseStoragePaths.userProfileImage(cleanUserId, fileName);

      return await uploadImage(
        path: filePath,
        imageData: imageData,
        contentType: 'image/jpeg',
        maxSizeMB: 5.0, // Profile images are smaller
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to upload user profile image', e, stackTrace, 'FirebaseStorageService');
      return null;
    }
  }

  /// Upload product image
  /// 
  /// [barcode] - Product barcode
  /// [imageData] - File (mobile) or Uint8List (web)
  /// 
  /// Returns download URL on success, null on failure
  Future<String?> uploadProductImage(
    String barcode,
    dynamic imageData,
  ) async {
    try {
      // Generate unique filename
      final cleanBarcode = barcode.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      if (cleanBarcode.isEmpty) {
        throw Exception('El código de barras no es válido');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 6);
      final fileName = 'product_${cleanBarcode}_$randomSuffix.jpg';

      // Build file path: products/{barcode}/{filename}
      final filePath = 'products/$cleanBarcode/$fileName';

      return await uploadImage(
        path: filePath,
        imageData: imageData,
        contentType: 'image/jpeg',
        maxSizeMB: 10.0,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to upload product image', e, stackTrace, 'FirebaseStorageService');
      return null;
    }
  }

  /// Upload pantry item image
  /// 
  /// [userId] - User ID
  /// [itemId] - Pantry item ID
  /// [imageData] - File (mobile) or Uint8List (web)
  /// 
  /// Returns download URL on success, null on failure
  Future<String?> uploadPantryItemImage(
    String userId,
    String itemId,
    dynamic imageData,
  ) async {
    try {
      // Generate unique filename
      final cleanUserId = userId.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      final cleanItemId = itemId.trim().replaceAll(RegExp(r'[^\w-]'), '_');
      
      if (cleanUserId.isEmpty || cleanItemId.isEmpty) {
        throw Exception('El ID del usuario o del artículo no es válido');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 6);
      final fileName = 'pantry_${cleanItemId}_$randomSuffix.jpg';

      // Build file path
      final filePath = FirebaseStoragePaths.pantryItemImage(cleanUserId, cleanItemId, fileName);

      return await uploadImage(
        path: filePath,
        imageData: imageData,
        contentType: 'image/jpeg',
        maxSizeMB: 5.0,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to upload pantry item image', e, stackTrace, 'FirebaseStorageService');
      return null;
    }
  }

  /// Delete an image from Firebase Storage
  /// 
  /// [imageUrl] - Full download URL of the image
  /// 
  /// Returns true on success, false on failure
  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        Logger.warning('Cannot delete image: URL is empty', 'FirebaseStorageService');
        return false;
      }

      // Extract path from URL
      final path = _extractPathFromUrl(imageUrl);
      if (path == null) {
        Logger.warning('Cannot extract path from URL: $imageUrl', 'FirebaseStorageService');
        return false;
      }

      Logger.info('Deleting image: $path', 'FirebaseStorageService');

      // Create reference and delete
      final storageRef = _storage.ref(path);
      await storageRef.delete();

      Logger.success('Image deleted successfully: $path', 'FirebaseStorageService');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to delete image from Firebase Storage', e, stackTrace, 'FirebaseStorageService');

      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('object-not-found') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        Logger.warning('Image not found (may have been already deleted): $imageUrl', 'FirebaseStorageService');
        return true; // Consider it successful if already deleted
      }

      if (errorMessage.contains('permission') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        Logger.warning('Storage permission denied. Please check Firebase Storage security rules.', 'FirebaseStorageService');
        return false;
      }

      return false;
    }
  }

  /// Delete recipe image
  Future<bool> deleteRecipeImage(String imageUrl) async {
    return await deleteImage(imageUrl);
  }

  /// Delete user profile image
  Future<bool> deleteUserProfileImage(String imageUrl) async {
    return await deleteImage(imageUrl);
  }

  /// Delete pantry item image
  Future<bool> deletePantryItemImage(String imageUrl) async {
    return await deleteImage(imageUrl);
  }

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

  /// Clean storage path (remove invalid characters, ensure proper format)
  String _cleanPath(String path) {
    // Remove leading/trailing slashes
    path = path.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    // Replace multiple slashes with single slash
    path = path.replaceAll(RegExp(r'/+'), '/');

    // Remove invalid characters (keep alphanumeric, dash, underscore, slash, dot)
    path = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');

    return path;
  }

  /// Extract storage path from download URL
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Firebase Storage URLs typically have format:
      // https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
      // or
      // https://storage.googleapis.com/{bucket}/{path}

      // Find the path after 'o/' or after bucket name
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex < pathSegments.length - 1) {
        // Decode the path (it's URL encoded)
        return Uri.decodeComponent(pathSegments[oIndex + 1]);
      }

      // Alternative format: direct path after bucket
      if (pathSegments.length > 1) {
        // Skip bucket name (first segment)
        return pathSegments.sublist(1).join('/');
      }

      return null;
    } catch (e) {
      Logger.warning('Failed to extract path from URL: $url, error: $e', 'FirebaseStorageService');
      return null;
    }
  }

  /// Get upload progress stream
  /// 
  /// Use this to track upload progress in the UI
  Stream<double>? getUploadProgress(String path, dynamic imageData) {
    try {
      final cleanPath = _cleanPath(path);
      if (cleanPath.isEmpty) return null;

      final storageRef = _storage.ref(cleanPath);

      UploadTask uploadTask;
      if (imageData is File) {
        uploadTask = storageRef.putFile(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (imageData is Uint8List) {
        uploadTask = storageRef.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        return null;
      }

      return uploadTask.snapshotEvents.map((snapshot) {
        return snapshot.bytesTransferred / snapshot.totalBytes;
      });
    } catch (e) {
      Logger.error('Failed to get upload progress', e, null, 'FirebaseStorageService');
      return null;
    }
  }
}

