import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../core/widgets/modern_snackbar.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/recipe_header.dart';
import '../widgets/ingredient_item.dart';
import '../widgets/instruction_step_card.dart';
import '../widgets/recipe_cost_widget.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../services/recipe_recommendation_service.dart';
import '../../../../services/recipe_sharing_service.dart';

/// Modern, minimal recipe detail page with Notion-style design
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isLoading = ref.watch(recipeControllerProvider).isLoading;
    final isOwner = currentUserId == widget.recipe.authorId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    
    // Fetch pantry items to check ingredient availability
    final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);
    final pantryItemNames = pantryItemsAsync.maybeWhen(
      data: (items) => items
          .map((item) => RecipeRecommendationService.formatIngredientNameForStorage(item.name.toLowerCase()))
          .toSet(),
      orElse: () => <String>{},
    );
    
    // Calculate availability for each ingredient
    Map<String, bool> ingredientAvailability = {};
    int availableCount = 0;
    for (final ingredient in _currentRecipe.ingredients) {
      final normalizedName = RecipeRecommendationService.formatIngredientNameForStorage(ingredient.name.toLowerCase());
      final isAvailable = pantryItemNames.contains(normalizedName);
      ingredientAvailability[ingredient.name] = isAvailable;
      if (isAvailable) availableCount++;
    }
    final missingCount = _currentRecipe.ingredients.length - availableCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: StandardAppBar(
        title: 'Receta',
        showBackButton: true,
        actions: [
          // Share button (Phase 2) - visible to all users
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: isLoading
                  ? null
                  : () {
                      _shareRecipe(context, ref);
                    },
            ),
          ),
          if (isOwner) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: isLoading
                    ? null
                    : () async {
                        final result = await context.push<bool>(
                          Routes.recipeEdit,
                          extra: widget.recipe,
                        );
                        if (result == true && context.mounted) {
                          ModernSnackbar.showSuccess(
                            context,
                            message: 'Receta actualizada exitosamente',
                          );
                        }
                      },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: isLoading
                    ? null
                    : () {
                        _showDeleteDialog(context, ref);
                      },
              ),
            ),
          ],
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Recipe Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    24,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: RecipeHeader(
                    recipe: _currentRecipe,
                    isTablet: isTablet,
                  ),
                ),
              ),

              // Recipe Cost Widget (Phase 2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    32,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: RecipeCostWidget(
                    recipe: _currentRecipe,
                    isTablet: isTablet,
                  ),
                ),
              ),

              // Generate Shopping List Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    16,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: _buildShoppingListButton(context, ref, isTablet),
                ),
              ),

              // Share Recipe Button (Phase 2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    16,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: _buildShareButton(context, ref, isTablet),
                ),
              ),

              // Ingredients Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    48,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: _buildSectionHeader('Ingredientes', isTablet),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    24,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: Column(
                    children: [
                      // Availability summary card
                      if (pantryItemsAsync.hasValue) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: missingCount == 0
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: missingCount == 0
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: missingCount == 0
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  missingCount == 0
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.shopping_cart_outlined,
                                  size: 20,
                                  color: missingCount == 0
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      missingCount == 0
                                          ? 'Todos los ingredientes disponibles'
                                          : '$availableCount de ${_currentRecipe.ingredients.length} disponibles',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: missingCount == 0
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                    if (missingCount > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Faltan $missingCount ingrediente${missingCount > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Ingredient list
                      ..._currentRecipe.ingredients.asMap().entries.map((entry) {
                        final isAvailable = pantryItemsAsync.hasValue
                            ? ingredientAvailability[entry.value.name]
                            : null;
                        return IngredientItem(
                          ingredient: entry.value,
                          index: entry.key,
                          isTablet: isTablet,
                          isAvailable: isAvailable,
                          onLinksUpdated: (amazonUrl, walmartUrl) {
                            _handleIngredientLinkUpdate(
                              context,
                              ref,
                              entry.key,
                              amazonUrl,
                              walmartUrl,
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Instructions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    48,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: _buildSectionHeader('Instrucciones', isTablet),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    24,
                    isTablet ? 48 : 24,
                    48,
                  ),
                  child: Column(
                    children: widget.recipe.instructions.asMap().entries.map((entry) {
                      return InstructionStepCard(
                        instruction: entry.value,
                        stepNumber: entry.key + 1,
                        isTablet: isTablet,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isTablet) {
    return Row(
      children: [
        Container(
          width: 5,
          height: isTablet ? 32 : 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 26 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingListButton(BuildContext context, WidgetRef ref, bool isTablet) {
    final isLoading = ref.watch(shoppingListControllerProvider).isLoading;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _generateShoppingList(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 20 : 18,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generar Lista de Compras',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateShoppingList(BuildContext context, WidgetRef ref) async {
    try {
      final listId = await ref
          .read(shoppingListControllerProvider.notifier)
          .generateShoppingList(_currentRecipe);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Lista de compras generada exitosamente!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push(Routes.shoppingLists);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar lista de compras: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle ingredient purchase link updates
  Future<void> _handleIngredientLinkUpdate(
    BuildContext context,
    WidgetRef ref,
    int ingredientIndex,
    String? amazonUrl,
    String? walmartUrl,
  ) async {
    try {
      // Create updated ingredients list
      final updatedIngredients = List<RecipeIngredient>.from(_currentRecipe.ingredients);
      final currentIngredient = updatedIngredients[ingredientIndex];

      // Handle link updates:
      // - null means "don't change this link"
      // - empty string means "delete this link"
      // - non-empty string means "set this as the new link"
      String? newAmazonLink = currentIngredient.amazonLink;
      String? newWalmartLink = currentIngredient.walmartLink;

      if (amazonUrl != null) {
        newAmazonLink = amazonUrl.isEmpty ? null : amazonUrl;
      }
      if (walmartUrl != null) {
        newWalmartLink = walmartUrl.isEmpty ? null : walmartUrl;
      }

      updatedIngredients[ingredientIndex] = RecipeIngredient(
        name: currentIngredient.name,
        quantity: currentIngredient.quantity,
        unit: currentIngredient.unit,
        amazonLink: newAmazonLink,
        walmartLink: newWalmartLink,
      );

      // Create updated recipe
      final updatedRecipe = _currentRecipe.copyWith(
        ingredients: updatedIngredients,
      );

      // Update in Firestore
      await ref.read(recipeControllerProvider.notifier).updateRecipe(updatedRecipe);

      // Update local state
      setState(() {
        _currentRecipe = updatedRecipe;
      });

      if (context.mounted) {
        ModernSnackbar.showSuccess(
          context,
          message: 'Enlace guardado exitosamente',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al guardar enlace: ${e.toString()}',
        );
      }
    }
  }

  Widget _buildShareButton(BuildContext context, WidgetRef ref, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Compartir Receta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Social media buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                context,
                ref,
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareToSocial(context, ref, SocialPlatform.whatsapp),
              ),
              _buildSocialButton(
                context,
                ref,
                icon: Icons.camera_alt_rounded,
                label: 'Instagram',
                color: const Color(0xFFE4405F),
                onTap: () => _shareToSocial(context, ref, SocialPlatform.instagram),
              ),
              _buildSocialButton(
                context,
                ref,
                icon: Icons.music_note_rounded,
                label: 'TikTok',
                color: const Color(0xFF000000),
                onTap: () => _shareToSocial(context, ref, SocialPlatform.tiktok),
              ),
              _buildSocialButton(
                context,
                ref,
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => _shareToSocial(context, ref, SocialPlatform.facebook),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Copy link and native share buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyRecipeLink(context, ref),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copiar enlace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareRecipe(context, ref),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Más opciones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToSocial(BuildContext context, WidgetRef ref, SocialPlatform platform) async {
    try {
      final sharingService = ref.read(recipeSharingServiceProvider);
      await sharingService.shareToSocialPlatform(_currentRecipe, platform);
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al compartir: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _copyRecipeLink(BuildContext context, WidgetRef ref) async {
    try {
      final sharingService = ref.read(recipeSharingServiceProvider);
      await sharingService.copyRecipeLink(_currentRecipe);
      
      if (context.mounted) {
        ModernSnackbar.showSuccess(
          context,
          message: 'Enlace copiado. El enlace abrirá la receta cuando la página web esté publicada.',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al copiar enlace: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _shareRecipe(BuildContext context, WidgetRef ref) async {
    try {
      final sharingService = ref.read(recipeSharingServiceProvider);
      await sharingService.shareRecipe(_currentRecipe);
      
      if (context.mounted) {
        ModernSnackbar.showSuccess(
          context,
          message: 'Receta compartida exitosamente',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al compartir receta: ${e.toString()}',
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Eliminar Receta'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${widget.recipe.title}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(recipeControllerProvider.notifier).deleteRecipe(
                      widget.recipe.id,
                      imageUrl: widget.recipe.imageUrl,
                    );
                if (context.mounted) {
                  ModernSnackbar.showSuccess(
                    context,
                    message: 'Receta eliminada exitosamente',
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = e.toString();
                  if (errorMessage.contains('Exception: ')) {
                    errorMessage = errorMessage.replaceFirst('Exception: ', '');
                  }
                  
                  ModernSnackbar.showError(
                    context,
                    message: 'Error al eliminar receta: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}',
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}



