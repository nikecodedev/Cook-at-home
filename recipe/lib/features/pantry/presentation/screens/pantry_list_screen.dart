import 'dart:async';
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
import 'pantry_edit_screen.dart';
import 'barcode_scanner_screen.dart';
import '../widgets/pantry_analytics_widget.dart';
import '../widgets/refill_alerts_widget.dart';
import '../../../../models/product_model.dart';
import '../../../../models/refill_alert_model.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';

class PantryListScreen extends ConsumerStatefulWidget {
  const PantryListScreen({super.key});

  @override
  ConsumerState<PantryListScreen> createState() => _PantryListScreenState();
}

class _PantryListScreenState extends ConsumerState<PantryListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  PantryFilter _filter = PantryFilter();
  bool _showAdvancedFilters = false;
  Timer? _debounceTimer;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _updateFilter(PantryFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateFilter(_filter.copyWith(searchQuery: value.isEmpty ? null : value));
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
    final userId = ref.watch(currentUserIdProvider);
    
    // Stream refill alerts to show low stock badges on items
    final refillAlertsAsync = userId != null
        ? ref.watch(StreamProvider<List<RefillAlert>>((ref) {
            final service = ref.watch(refillAlertServiceProvider);
            return service.streamActiveRefillAlerts(userId);
          }))
        : const AsyncValue<List<RefillAlert>>.data([]);
    
    // Build a set of canonical ingredient IDs that have active alerts
    final alertedIngredientIds = refillAlertsAsync.maybeWhen(
      data: (alerts) => alerts.map((a) => a.canonicalIngredientId).toSet(),
      orElse: () => <String>{},
    );

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
                  _showAdvancedFilters = !_showAdvancedFilters;
                });
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.primaryDark.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final product = await context.push<Product?>(Routes.barcodeScanner);
                  if (product != null && context.mounted) {
                    context.push(Routes.pantryEdit, extra: product);
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'Escanear producto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              tooltip: 'Agregar ingrediente',
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
                // Refill Alerts (Phase 2)
                SliverToBoxAdapter(
                  child: const RefillAlertsWidget(),
                ),
                
                // Pantry Analytics (Phase 2) - always visible
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: PantryAnalyticsWidget(pantryItems: items),
                  ),
                ),

                // Search Bar with predictive search
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: SearchBarWidget(
                      controller: _searchController,
                      hintText: 'Buscar ingredientes de despensa...',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                // Sort/Filter Header - Always visible
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _buildSortFilterHeader(items),
                  ),
                ),
                // Advanced Filter Section
                if (_showAdvancedFilters)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildAdvancedFilterSection(items),
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
                          child: _buildPantryItemCard(context, ref, expiredItems[index], true, alertedIngredientIds),
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
                          child: _buildPantryItemCard(context, ref, expiringSoonItems[index], false, alertedIngredientIds),
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
                      child: _buildSectionHeader('✅ Todos los Ingredientes', AppColors.primary),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPantryItemCard(context, ref, normalItems[index], false, alertedIngredientIds),
                        ),
                        childCount: normalItems.length,
                      ),
                    ),
                  ),
                ],
                // No floating action button; keep normal bottom spacing only.
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
        loading: () => _buildSkeletonLoading(context),
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
      // Removed bottom "Agregar Artículo" button (use the AppBar '+' action instead).
    );
  }

  /// Build always-visible sort/filter header with dropdown and quick filters
  Widget _buildSortFilterHeader(List<PantryItem> allItems) {
    final categories = getPantryCategories(allItems);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort Dropdown Row
        Row(
          children: [
            // Sort Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray200.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PantrySortOption>(
                  value: _filter.sortOption,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  isDense: true,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    DropdownMenuItem(
                      value: PantrySortOption.expiringSoon,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          const Text('Por vencer pronto', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: PantrySortOption.mostUsed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Más usado', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: PantrySortOption.recentlyAdded,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          const Text('Recién agregado', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: PantrySortOption.alphabetical,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_by_alpha_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          const Text('A-Z', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: PantrySortOption.category,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_rounded, size: 16, color: AppColors.oliveGreen),
                          const SizedBox(width: 8),
                          const Text('Por categoría', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateFilter(_filter.copyWith(sortOption: value));
                    }
                  },
                ),
              ),
            ),
            const Spacer(),
            // Clear filters button
            if (_filter.hasActiveFilters)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            // Filter toggle button
            Container(
              decoration: BoxDecoration(
                color: _showAdvancedFilters ? AppColors.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showAdvancedFilters ? AppColors.primary : AppColors.gray200,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _showAdvancedFilters ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                tooltip: 'Más filtros',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick Filter Chips - Always visible
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Expiration quick filters
              _buildQuickFilterChip(
                label: 'Vencidos',
                icon: Icons.warning_rounded,
                isSelected: _filter.expirationStatus == ExpirationFilter.expired,
                color: AppColors.error,
                onTap: () {
                  if (_filter.expirationStatus == ExpirationFilter.expired) {
                    _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.all));
                  } else {
                    _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.expired));
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildQuickFilterChip(
                label: 'Por vencer',
                icon: Icons.schedule_rounded,
                isSelected: _filter.expirationStatus == ExpirationFilter.expiringSoon,
                color: AppColors.warning,
                onTap: () {
                  if (_filter.expirationStatus == ExpirationFilter.expiringSoon) {
                    _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.all));
                  } else {
                    _updateFilter(_filter.copyWith(expirationStatus: ExpirationFilter.expiringSoon));
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildQuickFilterChip(
                label: 'Frecuentes',
                icon: Icons.local_fire_department_rounded,
                isSelected: _filter.frequencyFilter == FrequencyFilter.frequentlyUsed,
                color: AppColors.primary,
                onTap: () {
                  if (_filter.frequencyFilter == FrequencyFilter.frequentlyUsed) {
                    _updateFilter(_filter.copyWith(clearFrequencyFilter: true));
                  } else {
                    _updateFilter(_filter.copyWith(frequencyFilter: FrequencyFilter.frequentlyUsed));
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildQuickFilterChip(
                label: 'Sin usar',
                icon: Icons.hourglass_empty_rounded,
                isSelected: _filter.frequencyFilter == FrequencyFilter.neverUsed,
                color: AppColors.textSecondary,
                onTap: () {
                  if (_filter.frequencyFilter == FrequencyFilter.neverUsed) {
                    _updateFilter(_filter.copyWith(clearFrequencyFilter: true));
                  } else {
                    _updateFilter(_filter.copyWith(frequencyFilter: FrequencyFilter.neverUsed));
                  }
                },
              ),
              // Category chips if available
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1,
                  color: AppColors.gray200,
                ),
                const SizedBox(width: 8),
                ...categories.take(3).map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildQuickFilterChip(
                    label: Translations.translatePantryCategory(category),
                    icon: Icons.category_outlined,
                    isSelected: _filter.category == category,
                    color: AppColors.oliveGreen,
                    onTap: () {
                      if (_filter.category == category) {
                        _updateFilter(_filter.copyWith(clearCategory: true));
                      } else {
                        _updateFilter(_filter.copyWith(category: category));
                      }
                    },
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build a quick filter chip with custom styling
  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppColors.gray200,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build advanced filter section (expanded view)
  Widget _buildAdvancedFilterSection(List<PantryItem> allItems) {
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
                'Filtros Avanzados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showAdvancedFilters = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estado de Vencimiento
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
          const SizedBox(height: 20),
          
          // Frecuencia de Uso
          const Text(
            'Frecuencia de Uso',
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
                isSelected: _filter.frequencyFilter == null || _filter.frequencyFilter == FrequencyFilter.all,
                onTap: () => _updateFilter(_filter.copyWith(clearFrequencyFilter: true)),
                icon: Icons.all_inclusive,
              ),
              FilterChipWidget(
                label: 'Frecuentes (5+)',
                isSelected: _filter.frequencyFilter == FrequencyFilter.frequentlyUsed,
                onTap: () => _updateFilter(_filter.copyWith(frequencyFilter: FrequencyFilter.frequentlyUsed)),
                icon: Icons.local_fire_department_rounded,
              ),
              FilterChipWidget(
                label: 'Ocasional (1-4)',
                isSelected: _filter.frequencyFilter == FrequencyFilter.occasionallyUsed,
                onTap: () => _updateFilter(_filter.copyWith(frequencyFilter: FrequencyFilter.occasionallyUsed)),
                icon: Icons.trending_flat_rounded,
              ),
              FilterChipWidget(
                label: 'Sin usar',
                isSelected: _filter.frequencyFilter == FrequencyFilter.neverUsed,
                onTap: () => _updateFilter(_filter.copyWith(frequencyFilter: FrequencyFilter.neverUsed)),
                icon: Icons.hourglass_empty_rounded,
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
                  label: 'Todas',
                  isSelected: _filter.category == null,
                  onTap: () => _updateFilter(_filter.copyWith(clearCategory: true)),
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

  /// Build skeleton loading state with shimmer animation
  Widget _buildSkeletonLoading(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton for analytics widget
          _buildShimmerContainer(height: 100, width: double.infinity),
          const SizedBox(height: 16),
          // Skeleton for search bar
          _buildShimmerContainer(height: 50, width: double.infinity),
          const SizedBox(height: 16),
          // Skeleton for sort/filter header
          Row(
            children: [
              _buildShimmerContainer(height: 40, width: 180),
              const Spacer(),
              _buildShimmerContainer(height: 36, width: 36),
            ],
          ),
          const SizedBox(height: 12),
          // Skeleton for quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildShimmerContainer(height: 32, width: 90),
              )),
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton for section header
          _buildShimmerContainer(height: 24, width: 150),
          const SizedBox(height: 16),
          // Skeleton for pantry items
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSkeletonItemCard(),
          )),
        ],
      ),
    );
  }

  /// Build shimmer container with animation
  Widget _buildShimmerContainer({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height > 40 ? 16 : 12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.gray100,
                AppColors.gray200.withOpacity(0.8),
                AppColors.gray100,
              ],
              stops: [
                0.0,
                _shimmerController.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonItemCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              // Icon placeholder with shimmer
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.gray100,
                      AppColors.gray200.withOpacity(0.8),
                      AppColors.gray100,
                    ],
                    stops: [
                      0.0,
                      _shimmerController.value,
                      1.0,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content placeholder with shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.gray200,
                            AppColors.gray300.withOpacity(0.6),
                            AppColors.gray200,
                          ],
                          stops: [
                            0.0,
                            _shimmerController.value,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.gray100,
                            AppColors.gray200.withOpacity(0.6),
                            AppColors.gray100,
                          ],
                          stops: [
                            0.0,
                            _shimmerController.value,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.gray100,
                            AppColors.gray200.withOpacity(0.6),
                            AppColors.gray100,
                          ],
                          stops: [
                            0.0,
                            _shimmerController.value,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
              'No Se Encontraron Ingredientes',
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
              'Comienza a agregar ingredientes para llevar un registro de lo que hay en tu despensa',
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
                'Agrega tu Primer Ingrediente',
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
    Set<String> alertedIngredientIds,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isLoading = ref.watch(pantryControllerProvider).isLoading;
    final itemColor = _getItemColor(item);
    final backgroundColor = itemColor.withOpacity(0.08);
    
    // Check if this item has a low stock alert
    final hasLowStockAlert = item.canonicalIngredientId != null &&
        alertedIngredientIds.contains(item.canonicalIngredientId);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with colored background - Fixed size for alignment
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
              // Content - Flexible to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Row - Always same height
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasLowStockAlert) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Bajo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quantity and Category - Cleaner layout
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                Translations.translatePantryCategory(item.category),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.expirationDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: itemColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
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
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Menu button - Horizontally aligned
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
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                              const Text('Editar Ingrediente'),
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
                                'Eliminar Ingrediente',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
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
        title: const Text('Eliminar Ingrediente'),
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
                      content: Text('Ingrediente eliminado exitosamente'),
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
                      content: Text('Error al eliminar ingrediente: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
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

