import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';
import '../core/router/app_router.dart';

/// Enum for supported social platforms
enum SocialPlatform {
  whatsapp,
  instagram,
  tiktok,
  facebook,
  native, // Native share sheet
}

/// Service for sharing recipes with native Android share sheet
class RecipeSharingService {
  /// Base URL for web deep links - using client's actual domain
  static const String webBaseUrl = 'https://cocinaentucasa.com';
  
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

  /// Share to a specific social platform
  Future<bool> shareToSocialPlatform(Recipe recipe, SocialPlatform platform) async {
    try {
      final shareText = _buildShareText(recipe);
      final webLink = '$webBaseUrl/recipe/${recipe.id}';
      final encodedText = Uri.encodeComponent(shareText);
      final encodedLink = Uri.encodeComponent(webLink);
      
      String? url;
      
      switch (platform) {
        case SocialPlatform.whatsapp:
          url = 'whatsapp://send?text=$encodedText';
          break;
        case SocialPlatform.facebook:
          url = 'https://www.facebook.com/sharer/sharer.php?u=$encodedLink&quote=$encodedText';
          break;
        case SocialPlatform.instagram:
          // Instagram doesn't support direct URL sharing, use native share
          await shareRecipe(recipe);
          return true;
        case SocialPlatform.tiktok:
          // TikTok doesn't support direct URL sharing, use native share
          await shareRecipe(recipe);
          return true;
        case SocialPlatform.native:
          await shareRecipe(recipe);
          return true;
      }
      
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          Logger.success('Recipe shared to ${platform.name}: ${recipe.id}', 'RecipeSharingService');
          return true;
        } else {
          // Fallback to native share if app not installed
          Logger.warning('${platform.name} not available, using native share', 'RecipeSharingService');
          await shareRecipe(recipe);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      Logger.error('Failed to share to ${platform.name}', e, null, 'RecipeSharingService');
      // Fallback to native share
      await shareRecipe(recipe);
      return true;
    }
  }

  /// Copy recipe link to clipboard
  Future<void> copyRecipeLink(Recipe recipe) async {
    try {
      final webLink = '$webBaseUrl/recipe/${recipe.id}';
      await Clipboard.setData(ClipboardData(text: webLink));
      Logger.success('Recipe link copied: ${recipe.id}', 'RecipeSharingService');
    } catch (e) {
      Logger.error('Failed to copy recipe link', e, null, 'RecipeSharingService');
      rethrow;
    }
  }

  /// Get the shareable web link for a recipe
  String getRecipeWebLink(Recipe recipe) {
    return '$webBaseUrl/recipe/${recipe.id}';
  }

  /// Build short share text optimized for social media virality
  String buildViralShareText(Recipe recipe) {
    final buffer = StringBuffer();
    
    buffer.writeln('🍳 ${recipe.title}');
    buffer.writeln();
    
    if (recipe.cookTime > 0) {
      buffer.write('⏱️ ${recipe.formattedCookTime} ');
    }
    
    if (recipe.numberOfServings != null) {
      buffer.write('| 🍽️ ${recipe.numberOfServings} porciones ');
    }
    
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('✨ ¡Descubre la receta completa en Cocina en tu Casa!');
    buffer.writeln('$webBaseUrl/recipe/${recipe.id}');
    
    return buffer.toString();
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
  /// Returns web link for sharing (app deep links not yet supported)
  String _generateDeepLink(Recipe recipe) {
    // Web deep link format: https://cocinaentucasa.com/recipe/{recipeId}
    final webDeepLink = '$webBaseUrl/recipe/${recipe.id}';
    
    // Only return the web link - app deep links require app configuration
    return webDeepLink;
  }

  /// Build share text with full recipe content (name, ingredients, cost info)
  String _buildShareText(Recipe recipe) {
    final buffer = StringBuffer();

    // Recipe title
    buffer.writeln('🍳 ${recipe.title}');
    buffer.writeln();

    // Key info
    if (recipe.cookTime > 0) {
      buffer.write('⏱️ ${recipe.formattedCookTime}');
      if (recipe.numberOfServings != null) {
        buffer.write(' | 🍽️ ${recipe.numberOfServings} porciones');
      }
      buffer.writeln();
    } else if (recipe.numberOfServings != null) {
      buffer.writeln('🍽️ ${recipe.numberOfServings} porciones');
    }

    // Ingredients list
    if (recipe.ingredients.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📋 Ingredientes:');
      for (final ingredient in recipe.ingredients) {
        final qty = ingredient.quantity % 1 == 0
            ? ingredient.quantity.toInt().toString()
            : ingredient.quantity.toStringAsFixed(1);
        buffer.writeln('  • ${ingredient.name} - $qty ${ingredient.unit}');
      }
    }

    buffer.writeln();
    buffer.writeln('✨ Descubre más recetas en Cocina en tu Casa');
    buffer.writeln(_generateDeepLink(recipe));

    return buffer.toString();
  }
}



