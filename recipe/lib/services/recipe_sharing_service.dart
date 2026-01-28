import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';
import '../core/router/app_router.dart';

/// Service for sharing recipes with native Android share sheet
class RecipeSharingService {
  /// Base URL for web deep links (update when web app is deployed)
  static const String webBaseUrl = 'https://cocinaentucasa.app'; // Placeholder
  
  /// App deep link scheme
  static const String appScheme = 'cocinaentucasa';
  
  /// Share a recipe using native share sheet
  /// Handles both text-only and image sharing automatically
  Future<void> shareRecipe(Recipe recipe) async {
    try {
      // Build share text with deep link
      final shareText = _buildShareText(recipe);
      
      // If recipe has an image, download and share with image
      if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
        try {
          final imageFile = await _downloadImage(recipe.imageUrl!);
          if (imageFile != null) {
            await Share.shareXFiles(
              [XFile(imageFile.path)],
              text: shareText,
              subject: recipe.title,
            );
            Logger.success('Recipe shared with image: ${recipe.id}', 'RecipeSharingService');
            return;
          }
        } catch (e) {
          Logger.warning('Failed to download image for sharing, sharing text only: $e', 'RecipeSharingService');
          // Fall through to text-only sharing
        }
      }
      
      // Share text only (no image or image download failed)
      await Share.share(
        shareText,
        subject: recipe.title,
      );

      Logger.success('Recipe shared: ${recipe.id}', 'RecipeSharingService');
    } catch (e) {
      Logger.error('Failed to share recipe', e, null, 'RecipeSharingService');
      rethrow;
    }
  }

  /// Download image from URL to temporary file for sharing
  Future<File?> _downloadImage(String imageUrl) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode != 200) {
        Logger.warning('Failed to download image: HTTP ${response.statusCode}', 'RecipeSharingService');
        return null;
      }
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Determine file extension from URL or content type
      String extension = 'jpg';
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('png')) {
          extension = 'png';
        } else if (contentType.contains('gif')) {
          extension = 'gif';
        } else if (contentType.contains('webp')) {
          extension = 'webp';
        }
      } else {
        // Try to get extension from URL
        final urlPath = Uri.parse(imageUrl).path;
        final urlExtension = path.extension(urlPath).toLowerCase();
        if (urlExtension.isNotEmpty) {
          extension = urlExtension.substring(1); // Remove the dot
        }
      }
      
      // Create temporary file
      final tempFile = File(path.join(tempDir.path, 'recipe_share_${DateTime.now().millisecondsSinceEpoch}.$extension'));
      
      // Write image bytes to file
      await tempFile.writeAsBytes(response.bodyBytes);
      
      Logger.info('Image downloaded to: ${tempFile.path}', 'RecipeSharingService');
      return tempFile;
    } catch (e) {
      Logger.error('Failed to download image for sharing', e, null, 'RecipeSharingService');
      return null;
    }
  }

  /// Generate deep link for recipe
  /// Returns app deep link (preferred) or web link (fallback)
  String _generateDeepLink(Recipe recipe) {
    // App deep link format: cocinaentucasa://recipe/{recipeId}
    final appDeepLink = '$appScheme://recipe/${recipe.id}';
    
    // Web deep link format: https://cocinaentucasa.app/recipe/{recipeId}
    final webDeepLink = '$webBaseUrl/recipe/${recipe.id}';
    
    // Return both (user can choose, or app can handle app link)
    return '$appDeepLink\n$webDeepLink';
  }

  /// Build short, predefined share text for recipe
  String _buildShareText(Recipe recipe) {
    final buffer = StringBuffer();
    
    // Recipe title
    buffer.writeln('🍳 ${recipe.title}');
    buffer.writeln();
    
    // Short description with key info
    if (recipe.cookTime > 0) {
      buffer.writeln('⏱️ ${recipe.formattedCookTime}');
    }
    
    if (recipe.numberOfServings != null) {
      buffer.writeln('🍽️ ${recipe.numberOfServings} servings');
    }
    
    if (recipe.ingredients.isNotEmpty) {
      buffer.writeln('📋 ${recipe.ingredients.length} ingredients');
    }
    
    buffer.writeln();
    
    // Deep link
    buffer.writeln('📱 View full recipe:');
    buffer.writeln(_generateDeepLink(recipe));
    
    return buffer.toString();
  }
}



