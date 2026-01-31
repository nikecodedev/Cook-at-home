import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/pantry_item_model.dart';
import '../../../../services/pantry_analytics_service.dart';
import 'package:intl/intl.dart';

/// Widget to display comprehensive pantry analytics
/// Shows: total value, estimated meals, coverage %, and efficiency score
class PantryAnalyticsWidget extends ConsumerWidget {
  final List<PantryItem> pantryItems;

  const PantryAnalyticsWidget({
    super.key,
    required this.pantryItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final analyticsService = ref.watch(pantryAnalyticsServiceProvider);

    // Empty state: always show a card so Phase 2 section is visible
    if (pantryItems.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return FutureBuilder<PantryAnalytics>(
      future: analyticsService.calculateComprehensiveAnalytics(pantryItems, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState(context, l10n);
        }

        final analytics = snapshot.data!;
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Análisis de Despensa',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main metrics grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Valor Total',
                      formatter.format(analytics.totalValue),
                      AppColors.primary,
                      Icons.attach_money_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Comidas Est.',
                      analytics.estimatedMealsAvailable.toString(),
                      AppColors.secondary,
                      Icons.restaurant_menu_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Coverage and Efficiency row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Cobertura',
                      '${analytics.coveragePercentage.toStringAsFixed(0)}%',
                      _getCoverageColor(analytics.coveragePercentage),
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Eficiencia',
                      '${analytics.efficiencyScore.toStringAsFixed(0)}',
                      _getEfficiencyColor(analytics.efficiencyScore),
                      Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),

              // Efficiency score visual indicator
              if (analytics.efficiencyScore > 0) ...[
                const SizedBox(height: 16),
                _buildEfficiencyBar(analytics.efficiencyScore),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyBar(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Puntuación de Eficiencia',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}/100',
              style: TextStyle(
                fontSize: 12,
                color: _getEfficiencyColor(score),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(_getEfficiencyColor(score)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
                const Text(
                    'Análisis de Despensa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Agrega ingredientes a tu despensa para ver el valor total, comidas estimadas, cobertura de recetas y puntuación de eficiencia.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCoverageColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color _getEfficiencyColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

