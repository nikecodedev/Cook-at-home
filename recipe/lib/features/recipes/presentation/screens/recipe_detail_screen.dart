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
                    recipe: widget.recipe,
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
                    children: widget.recipe.ingredients.asMap().entries.map((entry) {
                      return IngredientItem(
                        ingredient: entry.value,
                        index: entry.key,
                        isTablet: isTablet,
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
          .generateShoppingList(widget.recipe);

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

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Eliminar Receta',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${widget.recipe.title}"?',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF757575),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
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
                        content: Text(
                            'Error al eliminar receta: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
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
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
