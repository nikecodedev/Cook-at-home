import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/meal_plan_model.dart';
import '../../../../models/recipe_model.dart';
import '../../../../models/pantry_item_model.dart';
import '../../../../services/meal_plan_service.dart';
import '../../../../services/meal_plan_cost_service.dart';
import '../../../../services/firestore/firestore_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/modern_snackbar.dart';
import 'package:uuid/uuid.dart';

/// Meal plan screen with weekly calendar view and breakfast/lunch/dinner slots
class MealPlanScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const MealPlanScreen({
    super.key,
    this.initialDate,
  });

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  late DateTime _currentWeekStart;
  MealPlan? _currentMealPlan;
  bool _isLoading = false;
  MealPlanCostCalculation? _costCalculation;
  bool _isCalculatingCost = false;
  bool _isGeneratingShoppingList = false;

  final List<String> _dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];
  final Map<String, String> _mealTypeLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Almuerzo',
    'dinner': 'Cena',
  };

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getMonday(widget.initialDate ?? DateTime.now());
    _loadMealPlan();
  }

  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday;
    final daysFromMonday = weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  Future<void> _loadMealPlan() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mealPlanService = ref.read(mealPlanServiceProvider);
      final mealPlan = await mealPlanService.getMealPlanForWeek(
        userId,
        _currentWeekStart,
      );

      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
          _isLoading = false;
        });
        _calculateCost();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calculateCost() async {
    if (_currentMealPlan == null) {
      setState(() {
        _costCalculation = null;
      });
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isCalculatingCost = true;
    });

    try {
      final costService = ref.read(mealPlanCostServiceProvider);
      final calculation = await costService.calculateMealPlanCost(
        _currentMealPlan!,
        userId,
      );

      if (mounted) {
        setState(() {
          _costCalculation = calculation;
          _isCalculatingCost = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingCost = false;
        });
      }
    }
  }

  Future<void> _addRecipeToMealSlot(String dayKey, String mealType) async {
    // Navigate to recipe selection
    final recipe = await context.push<Recipe?>(Routes.recipes);
    if (recipe == null || !mounted) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final now = DateTime.now();
    final mealPlan = (_currentMealPlan ?? MealPlan(
      id: const Uuid().v4(),
      userId: userId,
      weekStartDate: _currentWeekStart,
      dailyRecipes: {},
      createdAt: now,
      updatedAt: now,
    )).setRecipeForMeal(dayKey, mealType, recipe.id);

    try {
      final mealPlanService = ref.read(mealPlanServiceProvider);
      await mealPlanService.saveMealPlan(mealPlan);

      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
        });
        _calculateCost();
        ModernSnackbar.showSuccess(
          context,
          message: 'Receta agregada al plan',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al agregar receta: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _removeRecipeFromMealSlot(String dayKey, String mealType) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _currentMealPlan == null) return;

    final mealPlan = _currentMealPlan!.setRecipeForMeal(dayKey, mealType, null);

    try {
      final mealPlanService = ref.read(mealPlanServiceProvider);
      await mealPlanService.saveMealPlan(mealPlan);

      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
        });
        _calculateCost();
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          message: 'Error al eliminar receta: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _generateShoppingList() async {
    if (_currentMealPlan == null) {
      ModernSnackbar.showError(
        context,
        message: 'No hay plan de comidas para generar lista',
      );
      return;
    }

    // Check if meal plan has any recipes assigned
    final recipeIds = _currentMealPlan!.allRecipeIds;
    if (recipeIds.isEmpty) {
      ModernSnackbar.showError(
        context,
        message: 'No hay recetas asignadas en el plan de comidas',
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ModernSnackbar.showError(
        context,
        message: 'No se pudo identificar al usuario',
      );
      return;
    }

    setState(() {
      _isGeneratingShoppingList = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Fetch pantry items first
      final pantryItems = await firestoreService.getPantryItems(userId);
      
      // Show loading message after pantry items are fetched (to avoid showing too early)
      if (mounted) {
        ModernSnackbar.showInfo(
          context,
          message: 'Generando lista de compras...',
          duration: const Duration(seconds: 2),
        );
      }
      
      // Generate shopping list from meal plan
      final shoppingListId = await firestoreService.generateShoppingListFromMealPlan(
        userId: userId,
        mealPlan: _currentMealPlan!,
        pantryItems: pantryItems,
      );

      // Get the created shopping list with items
      final shoppingList = await firestoreService.getShoppingList(userId, shoppingListId);

      if (mounted) {
        setState(() {
          _isGeneratingShoppingList = false;
        });

        if (shoppingList != null) {
          // Show success message with item count
          final itemCount = shoppingList.items.length;
          ModernSnackbar.showSuccess(
            context,
            message: 'Lista de compras generada con $itemCount ${itemCount == 1 ? 'artículo' : 'artículos'}',
          );
          
          // Small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigate directly to the created shopping list
          if (mounted) {
            context.push(Routes.shoppingList, extra: shoppingList);
          }
        } else {
          // Fallback: navigate to shopping lists screen
          ModernSnackbar.showSuccess(
            context,
            message: 'Lista de compras generada exitosamente',
          );
          if (mounted) {
            context.push(Routes.shoppingLists);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingShoppingList = false;
        });
        
        // Show user-friendly error message
        String errorMessage = 'Error al generar lista de compras';
        final errorString = e.toString();
        if (errorString.contains('Todos los ingredientes') || 
            errorString.contains('ya están en tu despensa')) {
          errorMessage = '¡Todos los ingredientes ya están en tu despensa!';
        } else if (errorString.contains('No recipes found') || 
                   errorString.contains('No hay recetas')) {
          errorMessage = 'No hay recetas en el plan de comidas';
        } else if (errorString.contains('No recipes found in meal plan')) {
          errorMessage = 'No hay recetas en el plan de comidas';
        } else {
          // Extract meaningful error message
          final match = RegExp(r'Exception:\s*(.+)').firstMatch(errorString);
          if (match != null) {
            errorMessage = match.group(1) ?? 'Error al generar lista de compras';
          } else {
            errorMessage = 'Error al generar lista de compras. Por favor, intenta de nuevo.';
          }
        }
        
        ModernSnackbar.showError(
          context,
          message: errorMessage,
        );
      }
    }
  }

  void _navigateWeek(int weeks) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * weeks));
    });
    _loadMealPlan();
  }

  String _getDayName(String dayKey) {
    switch (dayKey) {
      case 'monday':
        return 'Lunes';
      case 'tuesday':
        return 'Martes';
      case 'wednesday':
        return 'Miércoles';
      case 'thursday':
        return 'Jueves';
      case 'friday':
        return 'Viernes';
      case 'saturday':
        return 'Sábado';
      case 'sunday':
        return 'Domingo';
      default:
        return dayKey;
    }
  }

  DateTime _getDayDate(String dayKey) {
    final dayIndex = _dayKeys.indexOf(dayKey);
    return _currentWeekStart.add(Duration(days: dayIndex));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: l10n?.weeklyMealPlan ?? 'Plan Semanal',
        showBackButton: true,
        actions: [
          if (_currentMealPlan != null)
            IconButton(
              icon: _isGeneratingShoppingList
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shopping_cart_rounded),
              onPressed: _isGeneratingShoppingList ? null : _generateShoppingList,
              tooltip: _isGeneratingShoppingList 
                  ? 'Generando lista de compras...' 
                  : 'Generar lista de compras',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Week Navigation Header
                SliverToBoxAdapter(
                  child: _buildWeekHeader(context),
                ),

                // Cost Summary (Phase 2)
                if (_costCalculation != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 48 : 20,
                        20,
                        isTablet ? 48 : 20,
                        0,
                      ),
                      child: _buildCostSummary(context, isTablet),
                    ),
                  ),

                // Weekly Calendar
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 48 : 20,
                    24,
                    isTablet ? 48 : 20,
                    24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dayKey = _dayKeys[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildDayCard(context, dayKey, isTablet),
                        );
                      },
                      childCount: _dayKeys.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM dd', 'es');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _navigateWeek(-1),
            color: AppColors.primary,
          ),
          Column(
            children: [
              Text(
                '${dateFormat.format(_currentWeekStart)} - ${dateFormat.format(weekEnd)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy').format(_currentWeekStart),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _navigateWeek(1),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(BuildContext context, bool isTablet) {
    final l10n = AppLocalizations.of(context);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  Icons.attach_money_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.weeklyCost ?? 'Costo Semanal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCostItem(
                context,
                l10n?.weeklyCost ?? 'Total',
                formatter.format(_costCalculation!.totalWeeklyCost),
                AppColors.primary,
              ),
              _buildCostItem(
                context,
                l10n?.costPerDay ?? 'Por Día',
                formatter.format(_costCalculation!.costPerDay),
                AppColors.textPrimary,
              ),
              _buildCostItem(
                context,
                l10n?.missingIngredients ?? 'Faltantes',
                formatter.format(_costCalculation!.missingIngredientCost),
                AppColors.error,
              ),
            ],
          ),
          if (_isCalculatingCost) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostItem(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, String dayKey, bool isTablet) {
    final dayName = _getDayName(dayKey);
    final dayDate = _getDayDate(dayKey);
    final dateFormat = DateFormat('MMM dd', 'es');
    final dayCost = _costCalculation?.dailyCosts[dayKey] ?? 0.0;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(dayDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (dayCost > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatter.format(dayCost),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Meal Slots (Breakfast, Lunch, Dinner)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _mealTypes.map((mealType) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealSlot(context, dayKey, mealType, isTablet),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlot(
    BuildContext context,
    String dayKey,
    String mealType,
    bool isTablet,
  ) {
    final recipeId = _currentMealPlan?.getRecipeForMeal(dayKey, mealType);
    final mealLabel = _mealTypeLabels[mealType] ?? mealType;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: recipeId == null || recipeId.isEmpty
          ? _buildEmptyMealSlot(context, dayKey, mealType, mealLabel)
          : FutureBuilder<Recipe?>(
              future: _loadRecipe(recipeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final recipe = snapshot.data;
                if (recipe == null) {
                  return _buildEmptyMealSlot(context, dayKey, mealType, mealLabel);
                }

                return _buildMealSlotWithRecipe(
                  context,
                  dayKey,
                  mealType,
                  mealLabel,
                  recipe,
                );
              },
            ),
    );
  }

  Widget _buildEmptyMealSlot(
    BuildContext context,
    String dayKey,
    String mealType,
    String mealLabel,
  ) {
    return InkWell(
      onTap: () => _addRecipeToMealSlot(dayKey, mealType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getMealIcon(mealType),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para agregar receta',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlotWithRecipe(
    BuildContext context,
    String dayKey,
    String mealType,
    String mealLabel,
    Recipe recipe,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMealIcon(mealType),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                context.push(Routes.recipeDetail, extra: recipe);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (recipe.cookTime > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.formattedCookTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => _removeRecipeFromMealSlot(dayKey, mealType),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.restaurant_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Future<Recipe?> _loadRecipe(String recipeId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      return await firestoreService.getRecipe(recipeId);
    } catch (e) {
      return null;
    }
  }
}
