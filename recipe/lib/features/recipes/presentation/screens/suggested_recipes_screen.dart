import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/recipe_recommendation_provider.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../models/recipe_model.dart';
import '../../../../services/recipe_recommendation_service.dart';
import '../../../../widgets/modern_recipe_card.dart';
import '../../../../core/utils/logger.dart';
import 'recipe_detail_screen.dart';

class SuggestedRecipesScreen extends ConsumerWidget {
  const SuggestedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recipeRecommendationsStreamProvider);
    final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: recommendationsAsync.when(
        data: (recommendations) {
          if (recommendations.isEmpty) {
            return pantryItemsAsync.when(
              data: (pantryItems) => _buildEmptyState(context, hasPantryItems: pantryItems.isNotEmpty),
              loading: () => _buildEmptyState(context, hasPantryItems: false),
              error: (_, __) => _buildEmptyState(context, hasPantryItems: false),
            );
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recetas Sugeridas',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Basado en artículos de tu despensa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Recetas con ingredientes coincidentes de tu despensa. La probabilidad de coincidencia se calcula basándose en el número y tipo de elementos coincidentes.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Recipe Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recommendation = recommendations[index];
                      return _buildRecommendationCard(context, ref, recommendation);
                    },
                    childCount: recommendations.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar recomendaciones',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool hasPantryItems}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasPantryItems ? Icons.search_off_rounded : Icons.shopping_basket_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasPantryItems ? 'Aún No Hay Recomendaciones' : 'No Hay Artículos en la Despensa',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasPantryItems
                  ? 'Aún no hay recetas que coincidan con los artículos de tu despensa. Intenta agregar más ingredientes a tu despensa o explora diferentes recetas.'
                  : 'Agrega artículos a tu despensa para obtener sugerencias de recetas basadas en lo que tienes.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push(Routes.pantry);
              },
              icon: Icon(hasPantryItems ? Icons.add_circle_outline : Icons.add_shopping_cart),
              label: Text(hasPantryItems ? 'Agregar Más Artículos' : 'Ir a la Despensa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    WidgetRef ref,
    RecipeRecommendation recommendation,
  ) {
    final recipe = recommendation.recipe;
    final coverage = recommendation.coveragePercent;
    final availableCount = recommendation.availableIngredients.length;
    final missingCount = recommendation.missingIngredients.length;
    final totalCount = recipe.ingredients.length;
    final matchColor = _getMatchColor(coverage);
    final isLoading = ref.watch(shoppingListControllerProvider).isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ModernRecipeCard(
            recipe: recipe,
            matchPercentage: coverage.toString(),
            matchColor: matchColor,
            onTap: () {
              context.push(Routes.recipeDetail, extra: recipe);
            },
          ),
          // Ingredient Match Summary
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gray200,
                width: 1,
              ),
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
                // Match Percentage Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: matchColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: matchColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$coverage% Coincidencia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: matchColor,
                              ),
                            ),
                            Text(
                              '$availableCount de $totalCount ingredientes disponibles',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Available Ingredients
                if (availableCount > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        availableCount == 1
                            ? 'Tienes $availableCount ingrediente:'
                            : 'Tienes $availableCount ingredientes:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendation.availableIngredients
                        .take(5)
                        .map((ingredient) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                ingredient.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  if (availableCount > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child:                       Text(
                        '+ ${availableCount - 5} más disponibles',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                // Missing Ingredients
                if (missingCount > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        missingCount == 1
                            ? 'Falta $missingCount ingrediente:'
                            : 'Faltan $missingCount ingredientes:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendation.missingIngredients
                        .take(5)
                        .map((ingredient) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                ingredient.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  if (missingCount > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child:                       Text(
                        '+ ${missingCount - 5} más faltantes',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Generate Shopping List Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _generateShoppingList(context, ref, recommendation),
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.shopping_cart, size: 18),
                      label: Text(
                        isLoading
                            ? 'Generando...'
                            : 'Generar Lista de Compras con Artículos Faltantes',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateShoppingList(
    BuildContext context,
    WidgetRef ref,
    RecipeRecommendation recommendation,
  ) async {
    try {
      // Create a recipe with only missing ingredients for the shopping list
      final recipeWithMissingIngredients = recommendation.recipe.copyWith(
        ingredients: recommendation.missingIngredients,
      );

      final listId = await ref
          .read(shoppingListControllerProvider.notifier)
          .generateShoppingList(recipeWithMissingIngredients);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Lista de compras creada exitosamente!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                context.push(Routes.shoppingLists);
              },
            ),
          ),
        );
        Logger.success(
          'Shopping list generated from missing ingredients',
          'SuggestedRecipesScreen',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear lista de compras: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Logger.error(
          'Failed to generate shopping list',
          e,
          null,
          'SuggestedRecipesScreen',
        );
      }
    }
  }

  Color _getMatchColor(int percentage) {
    // Color coding based on match thresholds:
    // 100% = All ingredients match (success/green)
    // 75%+ = Most ingredients match (warning/orange)
    // 25%+ = Some ingredients match (info/red)
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 75) return AppColors.warning;
    if (percentage >= 25) return AppColors.info;
    return AppColors.error;
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getMatchColorGradient(int coverage) {
    // Match thresholds: 100%, 75%, 25%
    if (coverage >= 100) {
      return [
        AppColors.success,
        AppColors.success.withOpacity(0.8),
      ];
    } else if (coverage >= 75) {
      return [
        AppColors.warning,
        AppColors.warning.withOpacity(0.8),
      ];
    } else {
      // 25% to 74%
      return [
        AppColors.info,
        AppColors.info.withOpacity(0.8),
      ];
    }
  }

  IconData _getMatchIcon(int coverage) {
    // Match thresholds: 100%, 75%, 25%
    if (coverage >= 100) {
      return Icons.check_circle_rounded;
    } else if (coverage >= 75) {
      return Icons.thumb_up_rounded;
    } else {
      // 25% to 74%
      return Icons.info_rounded;
    }
  }
}

