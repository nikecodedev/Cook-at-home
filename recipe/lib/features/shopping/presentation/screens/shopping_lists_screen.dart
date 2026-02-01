import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/utils/filter_utils.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../models/shopping_list_model.dart';
import 'shopping_list_screen.dart';

class ShoppingListsScreen extends ConsumerStatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  ConsumerState<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends ConsumerState<ShoppingListsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ShoppingListFilter _filter = ShoppingListFilter();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(ShoppingListFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  int _getActiveCount(List<ShoppingList> lists) {
    return lists.where((l) => !l.isArchived).length;
  }

  int _getArchivedCount(List<ShoppingList> lists) {
    return lists.where((l) => l.isArchived).length;
  }

  Widget _buildArchiveFilterTabs(List<ShoppingList> lists) {
    final activeCount = _getActiveCount(lists);
    final archivedCount = _getArchivedCount(lists);
    final totalCount = lists.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildArchiveTab(
              label: 'Activas',
              count: activeCount,
              isSelected: _filter.archiveMode == ArchiveFilterMode.active,
              onTap: () => _updateFilter(_filter.copyWith(archiveMode: ArchiveFilterMode.active)),
            ),
          ),
          Expanded(
            child: _buildArchiveTab(
              label: 'Archivadas',
              count: archivedCount,
              isSelected: _filter.archiveMode == ArchiveFilterMode.archived,
              onTap: () => _updateFilter(_filter.copyWith(archiveMode: ArchiveFilterMode.archived)),
            ),
          ),
          Expanded(
            child: _buildArchiveTab(
              label: 'Todas',
              count: totalCount,
              isSelected: _filter.archiveMode == ArchiveFilterMode.all,
              onTap: () => _updateFilter(_filter.copyWith(archiveMode: ArchiveFilterMode.all)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gray300.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.15) 
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Listas de Compras',
        showBackButton: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: Colors.white,
                size: 20,
              ),
              tooltip: _showFilters ? 'Ocultar opciones' : 'Mostrar opciones',
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
          ),
        ],
      ),
      body: listsAsync.when(
        data: (lists) {
          // Apply filters
          final filteredLists = _filter.applyFilters(lists);
          
          if (lists.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shoppingListsStreamProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Search Bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: SearchBarWidget(
                      controller: _searchController,
                      hintText: 'Buscar listas de compras...',
                      onChanged: (value) {
                        _updateFilter(_filter.copyWith(searchQuery: value.isEmpty ? null : value));
                      },
                    ),
                  ),
                ),
                // Archive Filter Tabs
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildArchiveFilterTabs(lists),
                  ),
                ),
                // Filter Section
                if (_showFilters)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildFilterSection(),
                    ),
                  ),
                // Lists
                if (filteredLists.isEmpty)
                  SliverFillRemaining(
                    child: _buildNoResultsState(context),
                  )
                else if (_filter.groupOption != ShoppingListGroupOption.none)
                  ..._buildGroupedLists(filteredLists)
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final list = filteredLists[index];
                          return _buildListCard(context, ref, list);
                        },
                        childCount: filteredLists.length,
                      ),
                    ),
                  ),
                // Bottom spacing
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
        loading: () => _buildSkeletonLoading(),
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
                'Error al cargar listas de compras: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Ordenar por',
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
              _buildFilterChip(
                label: 'Recientes',
                isSelected: _filter.sortOption == ShoppingListSortOption.recentFirst,
                onTap: () => _updateFilter(_filter.copyWith(sortOption: ShoppingListSortOption.recentFirst)),
                icon: Icons.schedule_rounded,
              ),
              _buildFilterChip(
                label: 'Antiguas',
                isSelected: _filter.sortOption == ShoppingListSortOption.oldestFirst,
                onTap: () => _updateFilter(_filter.copyWith(sortOption: ShoppingListSortOption.oldestFirst)),
                icon: Icons.history_rounded,
              ),
              _buildFilterChip(
                label: 'A-Z',
                isSelected: _filter.sortOption == ShoppingListSortOption.alphabetical,
                onTap: () => _updateFilter(_filter.copyWith(sortOption: ShoppingListSortOption.alphabetical)),
                icon: Icons.sort_by_alpha_rounded,
              ),
              _buildFilterChip(
                label: 'Por receta',
                isSelected: _filter.sortOption == ShoppingListSortOption.byRecipe,
                onTap: () => _updateFilter(_filter.copyWith(sortOption: ShoppingListSortOption.byRecipe)),
                icon: Icons.restaurant_menu_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Agrupar',
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
              _buildFilterChip(
                label: 'Sin agrupar',
                isSelected: _filter.groupOption == ShoppingListGroupOption.none,
                onTap: () => _updateFilter(_filter.copyWith(groupOption: ShoppingListGroupOption.none)),
                icon: Icons.list_rounded,
              ),
              _buildFilterChip(
                label: 'Por semana',
                isSelected: _filter.groupOption == ShoppingListGroupOption.byWeek,
                onTap: () => _updateFilter(_filter.copyWith(groupOption: ShoppingListGroupOption.byWeek)),
                icon: Icons.calendar_view_week_rounded,
              ),
              _buildFilterChip(
                label: 'Por receta',
                isSelected: _filter.groupOption == ShoppingListGroupOption.byRecipe,
                onTap: () => _updateFilter(_filter.copyWith(groupOption: ShoppingListGroupOption.byRecipe)),
                icon: Icons.restaurant_menu_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tipo de origen',
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
              _buildFilterChip(
                label: 'Todos',
                isSelected: _filter.source == null,
                onTap: () => _updateFilter(ShoppingListFilter(
                  searchQuery: _filter.searchQuery,
                  sortOption: _filter.sortOption,
                  archiveMode: _filter.archiveMode,
                  groupOption: _filter.groupOption,
                  source: null,
                )),
                icon: Icons.all_inclusive,
              ),
              _buildFilterChip(
                label: 'De recetas',
                isSelected: _filter.source == 'recipe',
                onTap: () => _updateFilter(ShoppingListFilter(
                  searchQuery: _filter.searchQuery,
                  sortOption: _filter.sortOption,
                  archiveMode: _filter.archiveMode,
                  groupOption: _filter.groupOption,
                  source: 'recipe',
                )),
                icon: Icons.restaurant_menu_rounded,
              ),
              _buildFilterChip(
                label: 'De plan semanal',
                isSelected: _filter.source == 'meal_plan',
                onTap: () => _updateFilter(ShoppingListFilter(
                  searchQuery: _filter.searchQuery,
                  sortOption: _filter.sortOption,
                  archiveMode: _filter.archiveMode,
                  groupOption: _filter.groupOption,
                  source: 'meal_plan',
                )),
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedLists(List<ShoppingList> lists) {
    final Map<String, List<ShoppingList>> grouped;
    final IconData groupIcon;
    
    if (_filter.groupOption == ShoppingListGroupOption.byWeek) {
      grouped = _filter.groupByWeek(lists);
      groupIcon = Icons.calendar_view_week_rounded;
    } else {
      grouped = _filter.groupByRecipe(lists);
      groupIcon = Icons.restaurant_menu_rounded;
    }
    
    final widgets = <Widget>[];
    
    for (final entry in grouped.entries) {
      // Group header
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    groupIcon,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Lists in group
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildListCard(context, ref, entry.value[index]);
              },
              childCount: entry.value.length,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
              'No se encontraron listas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta ajustar tus filtros o búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún No Hay Listas de Compras',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Genera una lista de compras desde una receta para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, WidgetRef ref, ShoppingList list) {
    final isLoading = ref.watch(shoppingListControllerProvider).isLoading;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: list.isArchived ? AppColors.gray100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: list.isArchived ? AppColors.gray300 : AppColors.gray200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(list.isArchived ? 0.05 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(Routes.shoppingList, extra: list);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: list.isArchived 
                        ? AppColors.gray200 
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    list.isArchived ? Icons.inventory_2_outlined : Icons.shopping_cart,
                    color: list.isArchived ? AppColors.textSecondary : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              list.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: list.isArchived 
                                    ? AppColors.textSecondary 
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (list.isArchived) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gray200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Archivada',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          if (list.isFromMealPlan && !list.isArchived) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Auto',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Creado ${_formatDate(list.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (list.recipeTitle != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.restaurant_menu_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                list.recipeTitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context, ref, list);
                    } else if (value == 'archive') {
                      _toggleArchive(context, ref, list);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, ref, list);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      enabled: !isLoading,
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                          SizedBox(width: 12),
                          Text('Renombrar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      enabled: !isLoading,
                      child: Row(
                        children: [
                          Icon(
                            list.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Text(list.isArchived ? 'Desarchivar' : 'Archivar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !isLoading,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          SizedBox(width: 12),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref, ShoppingList list) async {
    try {
      await ref.read(shoppingListControllerProvider.notifier).archiveShoppingList(
            listId: list.id,
            isArchived: !list.isArchived,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(list.isArchived ? 'Lista desarchivada' : 'Lista archivada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ShoppingList list) {
    final nameController = TextEditingController(text: list.name);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Renombrar Lista',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre de la lista',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ej: Compras del fin de semana',
                    hintStyle: const TextStyle(
                      color: AppColors.gray400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.gray100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              nameController.clear();
                              setDialogState(() {});
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre no puede estar vacío';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                  onChanged: (value) => setDialogState(() {}),
                  onFieldSubmitted: (_) async {
                    if (!isLoading && formKey.currentState!.validate()) {
                      await _submitRename(
                        context,
                        ref,
                        list,
                        nameController.text.trim(),
                        setDialogState,
                        (loading) => isLoading = loading,
                      );
                    }
                  },
                ),
                if (list.recipeTitle != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Receta: ${list.recipeTitle}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isLoading ? AppColors.gray400 : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        await _submitRename(
                          context,
                          ref,
                          list,
                          nameController.text.trim(),
                          setDialogState,
                          (loading) => isLoading = loading,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRename(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    String newName,
    void Function(void Function()) setDialogState,
    void Function(bool) setLoading,
  ) async {
    if (newName == list.name) {
      Navigator.of(context).pop();
      return;
    }

    setDialogState(() => setLoading(true));

    try {
      await ref.read(shoppingListControllerProvider.notifier).updateShoppingList(
            listId: list.id,
            name: newName,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Lista renombrada exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setDialogState(() => setLoading(false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Lista de Compras'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${list.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(shoppingListControllerProvider.notifier).deleteShoppingList(list.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lista de compras eliminada exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

