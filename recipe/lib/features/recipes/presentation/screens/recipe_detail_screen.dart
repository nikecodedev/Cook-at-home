import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../models/recipe_model.dart';
import '../widgets/recipe_header.dart';
import '../widgets/ingredient_item.dart';
import '../widgets/instruction_step_card.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: StandardAppBar(
        title: 'Receta',
        showBackButton: true,
        actions: isOwner
            ? [
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
                        : () {
                            context.push(Routes.recipeEdit, extra: widget.recipe);
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
              ]
            : null,
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

              // Generate Shopping List Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 24,
                    32,
                    isTablet ? 48 : 24,
                    0,
                  ),
                  child: _buildShoppingListButton(context, ref, isTablet),
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
                    children: _currentRecipe.ingredients.asMap().entries.map((entry) {
                      return IngredientItem(
                        ingredient: entry.value,
                        index: entry.key,
                        isTablet: isTablet,
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
                    }).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Enlace guardado exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar enlace: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receta eliminada exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = e.toString();
                  if (errorMessage.contains('Exception: ')) {
                    errorMessage = errorMessage.replaceFirst('Exception: ', '');
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar receta: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Descartar',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
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



