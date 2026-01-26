import 'package:share_plus/share_plus.dart';
import '../models/recipe_model.dart';
import '../core/utils/logger.dart';

/// Service for sharing recipes
class RecipeSharingService {
  /// Share a recipe using native share sheet
  Future<void> shareRecipe(Recipe recipe) async {
    try {
      // Build share text
      final shareText = _buildShareText(recipe);
      
      // Share with native share sheet
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

  /// Share recipe with image (if available)
  Future<void> shareRecipeWithImage(
    Recipe recipe,
    String imagePath,
  ) async {
    try {
      final shareText = _buildShareText(recipe);
      
      // Share with image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: recipe.title,
      );

      Logger.success('Recipe shared with image: ${recipe.id}', 'RecipeSharingService');
    } catch (e) {
      Logger.error('Failed to share recipe with image', e, null, 'RecipeSharingService');
      rethrow;
    }
  }

  /// Build share text for recipe
  String _buildShareText(Recipe recipe) {
    final buffer = StringBuffer();
    
    // Recipe title
    buffer.writeln('🍳 ${recipe.title}');
    buffer.writeln();
    
    // Ingredients
    if (recipe.ingredients.isNotEmpty) {
      buffer.writeln('📋 Ingredients:');
      for (final ingredient in recipe.ingredients) {
        buffer.writeln('• ${ingredient.quantity} ${ingredient.unit} ${ingredient.name}');
      }
      buffer.writeln();
    }
    
    // Cook time
    if (recipe.cookTime > 0) {
      buffer.writeln('⏱️ Cook time: ${recipe.formattedCookTime}');
      buffer.writeln();
    }
    
    // Yield and servings (if available)
    if (recipe.yieldValue != null && recipe.yieldUnit != null) {
      buffer.writeln('📊 Yield: ${recipe.yieldValue} ${recipe.yieldUnit}');
      if (recipe.numberOfServings != null) {
        buffer.writeln('🍽️ Servings: ${recipe.numberOfServings}');
      }
      buffer.writeln();
    }
    
    // Instructions preview (first 2 steps)
    if (recipe.instructions.isNotEmpty) {
      buffer.writeln('👨‍🍳 Instructions:');
      final previewSteps = recipe.instructions.take(2);
      for (var i = 0; i < previewSteps.length; i++) {
        buffer.writeln('${i + 1}. ${previewSteps.elementAt(i)}');
      }
      if (recipe.instructions.length > 2) {
        buffer.writeln('...');
      }
      buffer.writeln();
    }
    
    // App link (placeholder - replace with actual app link)
    buffer.writeln('📱 View full recipe in Cocina en tu Casa app');
    // TODO: Add deep link or web link when available
    
    return buffer.toString();
  }
}

