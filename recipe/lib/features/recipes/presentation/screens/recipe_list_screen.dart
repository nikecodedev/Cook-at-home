import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/utils/filter_utils.dart';
import '../../../../widgets/filter_chip_widget.dart';
import '../../../../widgets/modern_recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'suggested_recipes_screen.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  /// When true, tapping a recipe returns it (e.g. for meal plan selection) instead of opening detail.
  final bool selectForMealPlan;

  const RecipeListScreen({
    super.key,
    this.initialTabIndex = 0,
    this.selectForMealPlan = false,
  });

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  RecipeFilter _filter = RecipeFilter();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.selectForMealPlan ? 1 : 2;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, tabCount - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(RecipeFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = RecipeFilter();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: widget.selectForMealPlan ? 'Seleccionar receta' : 'Recetas',
        showBackButton: true,
        bottom: widget.selectForMealPlan
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                indicatorColor: Colors.transparent,
                indicatorWeight: 0,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                tabs: const [
                  Tab(text: 'Todas las Recetas'),
                  Tab(text: 'Sugeridas'),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              context.push(Routes.recipeAdd);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllRecipesTab(
            searchController: _searchController,
            filter: _filter,
            showFilters: _showFilters,
            onFilterChanged: _updateFilter,
            onClearFilters: _clearFilters,
            selectForMealPlan: widget.selectForMealPlan,
          ),
          if (!widget.selectForMealPlan) const SuggestedRecipesScreen(),
        ],
      ),
    );
  }
}

class _AllRecipesTab extends ConsumerWidget {
  final TextEditingController searchController;
  final RecipeFilter filter;
  final bool showFilters;
  final Function(RecipeFilter) onFilterChanged;
  final VoidCallback onClearFilters;
  final bool selectForMealPlan;

  const _AllRecipesTab({
    required this.searchController,
    required this.filter,
    required this.showFilters,
    required this.onFilterChanged,
    required this.onClearFilters,
    this.selectForMealPlan = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesStreamProvider);

    return recipesAsync.when(
      data: (recipes) {
        // Apply filters
        final filteredRecipes = filter.applyFilters(recipes);

        if (recipes.isEmpty) {
          return _buildEmptyState(context);
        }

        if (filteredRecipes.isEmpty && filter.hasActiveFilters) {
          return _buildNoResultsState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allRecipesStreamProvider);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Search Bar
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: SearchBarWidget(
                    controller: searchController,
                    hintText: 'Buscar recetas por nombre o ingrediente...',
                    onChanged: (value) {
                      onFilterChanged(filter.copyWith(searchQuery: value.isEmpty ? null : value));
                    },
                  ),
                ),
              ),
              // Filter Chips
              if (showFilters)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _buildFilterSection(recipes),
                  ),
                ),
              // Stats Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildStatsHeader(context, filteredRecipes.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRecipeCard(
                        context,
                        filteredRecipes[index],
                        selectForMealPlan: selectForMealPlan,
                      ),
                    ),
                    childCount: filteredRecipes.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        );
      },
      loading: () => _buildEmptyState(context),
      error: (error, stack) => Center(
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
              'Error al cargar recetas: $error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(allRecipesStreamProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(List<Recipe> allRecipes) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (filter.hasActiveFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text(
                    'Limpiar Todo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Cook Time Filter
          const Text(
            'Tiempo de Cocción',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChipWidget(
                label: 'Todas',
                isSelected: filter.cookTime == null || filter.cookTime == CookTimeFilter.all,
                onTap: () => onFilterChanged(filter.copyWith(cookTime: CookTimeFilter.all)),
                icon: Icons.all_inclusive,
              ),
              FilterChipWidget(
                label: 'Rápida (≤30 min)',
                isSelected: filter.cookTime == CookTimeFilter.quick,
                onTap: () => onFilterChanged(filter.copyWith(cookTime: CookTimeFilter.quick)),
                icon: Icons.flash_on_rounded,
              ),
              FilterChipWidget(
                label: 'Media (31-60 min)',
                isSelected: filter.cookTime == CookTimeFilter.medium,
                onTap: () => onFilterChanged(filter.copyWith(cookTime: CookTimeFilter.medium)),
                icon: Icons.timer_rounded,
              ),
              FilterChipWidget(
                label: 'Larga (>60 min)',
                isSelected: filter.cookTime == CookTimeFilter.long,
                onTap: () => onFilterChanged(filter.copyWith(cookTime: CookTimeFilter.long)),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Se Encontraron Recetas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta ajustar tus filtros o consulta de búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all, color: Colors.white),
              label: const Text(
                'Limpiar Filtros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún No Hay Recetas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza a agregar tus recetas favoritas para compartir con otros',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push(Routes.recipeAdd);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Agrega tu Primera Receta',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  Widget _buildStatsHeader(BuildContext context, int total) {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            '$total Recetas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe, {
    bool selectForMealPlan = false,
  }) {
    return ModernRecipeCard(
      recipe: recipe,
      onTap: () {
        if (selectForMealPlan) {
          context.pop(recipe);
        } else {
          context.push(Routes.recipeDetail, extra: recipe);
        }
      },
    );
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
}

