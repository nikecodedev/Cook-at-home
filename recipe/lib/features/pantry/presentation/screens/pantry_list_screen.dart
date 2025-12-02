import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../models/pantry_item_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/translations.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/utils/filter_utils.dart';
import '../../../../widgets/filter_chip_widget.dart';
import '../../../../core/widgets/purchase_button.dart';
import 'pantry_edit_screen.dart';

class PantryListScreen extends ConsumerStatefulWidget {
  const PantryListScreen({super.key});

  @override
  ConsumerState<PantryListScreen> createState() => _PantryListScreenState();
}

class _PantryListScreenState extends ConsumerState<PantryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  PantryFilter _filter = PantryFilter();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(PantryFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = PantryFilter();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsync = ref.watch(pantryItemsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Mi Despensa',
        showBackButton: true,
        actions: [
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
              icon: const Icon(
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
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                context.push(Routes.pantryEdit, extra: null);
              },
            ),
          ),
        ],
      ),
      body: pantryItemsAsync.when(
        data: (items) {
          // Apply filters
          final filteredItems = _filter.applyFilters(items);

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          if (filteredItems.isEmpty && _filter.hasActiveFilters) {
            return _buildNoResultsState(context);
          }

          // Group items by expiration status (only if no expiration filter is active)
          final expiredItems = _filter.expirationStatus == null
              ? filteredItems.where((item) => item.isExpired).toList()
              : (_filter.expirationStatus == ExpirationFilter.expired ? filteredItems : []);
          final expiringSoonItems = _filter.expirationStatus == null
              ? filteredItems.where((item) => item.isExpiringSoon && !item.isExpired).toList()
              : (_filter.expirationStatus == ExpirationFilter.expiringSoon ? filteredItems : []);
          final normalItems = _filter.expirationStatus == null
              ? filteredItems.where((item) => !item.isExpiringSoon && !item.isExpired).toList()
              : (_filter.expirationStatus == ExpirationFilter.normal ? filteredItems : []);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pantryItemsStreamProvider);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Search Bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: SearchBarWidget(
                      controller: _searchController,
                      hintText: 'Buscar artículos de despensa...',
                      onChanged: (value) {
                        _updateFilter(_filter.copyWith(searchQuery: value.isEmpty ? null : value));
                      },
                    ),
                  ),
                ),
                // Filter Chips
                if (_showFilters)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildFilterSection(items),
                    ),
                  ),
                // Stats Header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatsHeader(
                      context,
                      expiredItems.length,
                      expiringSoonItems.length,
                      filteredItems.length,
                    ),
                  ),
                ),
                if (expiredItems.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader('⚠️ Vencidos', AppColors.error),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPantryItemCard(context, ref, expiredItems[index], true),
                        ),
                        childCount: expiredItems.length,
                      ),
                    ),
                  ),
                ],
                if (expiringSoonItems.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader('⏰ Por Vencer', AppColors.warning),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPantryItemCard(context, ref, expiringSoonItems[index], false),
                        ),
                        childCount: expiringSoonItems.length,
                      ),
                    ),
                  ),
                ],
                if (normalItems.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader('✅ Todos los Artículos', AppColors.primary),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPantryItemCard(context, ref, normalItems[index], false),
                        ),
                        childCount: normalItems.length,
                      ),
                    ),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
                'Error al cargar la despensa: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(pantryItemsStreamProvider);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(Routes.pantryEdit, extra: null);
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Artículo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(List<PantryItem> allItems) {
    final categories = getPantryCategories(allItems);

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
              if (_filter.hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
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
          // Expiration Status Filter
          const Text(
            'Estado de Vencimiento',
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
                label: 'Todos',
                isSelected: _filter.expirationStatus == null || _filter.expirationStatus == ExpirationFilter.all,
                onTap: () => _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.all)),
                icon: Icons.all_inclusive,
              ),
              FilterChipWidget(
                label: 'Vencidos',
                isSelected: _filter.expirationStatus == ExpirationFilter.expired,
                onTap: () => _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.expired)),
                icon: Icons.warning_rounded,
              ),
              FilterChipWidget(
                label: 'Por Vencer',
                isSelected: _filter.expirationStatus == ExpirationFilter.expiringSoon,
                onTap: () => _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.expiringSoon)),
                icon: Icons.schedule_rounded,
              ),
              FilterChipWidget(
                label: 'Normal',
                isSelected: _filter.expirationStatus == ExpirationFilter.normal,
                onTap: () => _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.normal)),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Categoría',
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
                  label: 'Todas las Categorías',
                  isSelected: _filter.category == null,
                  onTap: () => _updateFilter(_filter.copyWith(category: null)),
                ),
                ...categories.map((category) => FilterChipWidget(
                      label: Translations.translatePantryCategory(category),
                      isSelected: _filter.category == category,
                      onTap: () => _updateFilter(_filter.copyWith(category: category)),
                    )),
              ],
            ),
          ],
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
              'No Se Encontraron Artículos',
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
              onPressed: _clearFilters,
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
              child: Icon(
                Icons.kitchen_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu Despensa Está Vacía',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza a agregar artículos para llevar un registro de lo que hay en tu despensa',
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
                context.push(Routes.pantryEdit, extra: null);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Agrega tu Primer Artículo',
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

  Widget _buildStatsHeader(BuildContext context, int expired, int expiring, int total) {
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), AppColors.textPrimary, Icons.inventory_2),
          if (expiring > 0)
            _buildStatItem('Por Vencer', expiring.toString(), AppColors.warning, Icons.schedule),
          if (expired > 0)
            _buildStatItem('Vencidos', expired.toString(), AppColors.error, Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPantryItemCard(
    BuildContext context,
    WidgetRef ref,
    PantryItem item,
    bool isExpired,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isLoading = ref.watch(pantryControllerProvider).isLoading;
    final itemColor = _getItemColor(item);
    final backgroundColor = itemColor.withOpacity(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(Routes.pantryEdit, extra: item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: itemColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: itemColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with colored background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getItemIcon(item),
                  color: itemColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isExpired || item.isExpiringSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: itemColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.isExpired ? 'Vencido' : '${item.daysUntilExpiration}d restantes',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: itemColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.scale_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.quantity} ${Translations.translateUnit(item.unit)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            Translations.translatePantryCategory(item.category),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.expirationDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: itemColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.isExpired
                                ? 'Vencido ${dateFormat.format(item.expirationDate!)}'
                                : item.isExpiringSoon
                                    ? 'Vence ${dateFormat.format(item.expirationDate!)}'
                                    : 'Vence ${dateFormat.format(item.expirationDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: itemColor,
                              fontWeight: item.isExpiringSoon || item.isExpired
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Buy buttons and menu
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Purchase buttons row
                  if (item.amazonUrl != null || item.walmartUrl != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.amazonUrl != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: PurchaseButton.amazon(
                              url: item.amazonUrl,
                              itemName: item.name,
                              size: PurchaseButtonSize.small,
                            ),
                          ),
                        if (item.amazonUrl != null && item.walmartUrl != null)
                          const SizedBox(width: 4),
                        if (item.walmartUrl != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: PurchaseButton.walmart(
                              url: item.walmartUrl,
                              itemName: item.name,
                              size: PurchaseButtonSize.small,
                            ),
                          ),
                      ],
                    ),
                  ],
                  // Menu button
                  isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push(Routes.pantryEdit, extra: item);
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, ref, item);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Editar Artículo'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Eliminar Artículo',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Color _getItemColor(PantryItem item) {
    if (item.isExpired) {
      return AppColors.error;
    } else if (item.isExpiringSoon) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  IconData _getItemIcon(PantryItem item) {
    if (item.isExpired) {
      return Icons.warning;
    } else if (item.isExpiringSoon) {
      return Icons.schedule;
    }
    return Icons.check_circle;
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, PantryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Artículo'),
        content: Text('¿Estás seguro de que deseas eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(pantryControllerProvider.notifier).deletePantryItem(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artículo eliminado exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = e.toString();
                  if (errorMessage.contains('Exception: ')) {
                    errorMessage = errorMessage.replaceFirst('Exception: ', '');
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar artículo: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
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

