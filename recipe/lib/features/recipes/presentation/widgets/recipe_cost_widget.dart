import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/recipe_model.dart';
import '../../../../services/recipe_cost_service.dart';
import '../../../../core/constants/firebase_constants.dart';

/// Widget to display recipe cost information
/// Automatically recalculates when recipe or prices change
class RecipeCostWidget extends ConsumerWidget {
  final Recipe recipe;
  final bool isTablet;

  const RecipeCostWidget({
    super.key,
    required this.recipe,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final costAsync = ref.watch(
      recipeCostProvider(
        RecipeCostParams(recipe: recipe, userId: userId),
      ),
    );

    return costAsync.when(
      data: (calculation) => _buildCostDisplay(context, calculation),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
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

  Widget _buildErrorState(BuildContext context, Object error) {
    // Silently hide on error - cost calculation is non-critical
    return const SizedBox.shrink();
  }

  Widget _buildCostDisplay(BuildContext context, RecipeCostCalculation calculation) {
    final l10n = AppLocalizations.of(context);

    // Don't show if no cost data
    if (calculation.totalCost == 0) {
      return const SizedBox.shrink();
    }

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
                l10n?.recipeCost ?? 'Recipe Cost',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCostItem(
                  context,
                  l10n?.totalCost ?? 'Total Cost',
                  '\$${calculation.totalCost.toStringAsFixed(2)}',
                  AppColors.textPrimary,
                ),
              ),
              if (calculation.costPerPortion != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCostItem(
                    context,
                    l10n?.costPerPortion ?? 'Per Portion',
                    '\$${calculation.costPerPortion!.toStringAsFixed(2)}',
                    AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getCostTierColor(calculation.costTier).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getCostTierColor(calculation.costTier).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _getCostTierColor(calculation.costTier),
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n?.costTier ?? 'Cost Tier'}: ${_getCostTierLabel(calculation.costTier, context)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCostTierColor(calculation.costTier),
                  ),
                ),
              ],
            ),
          ),
          if (calculation.numberOfServings != null) ...[
            const SizedBox(height: 12),
            Text(
              '${l10n?.numberOfServings ?? 'Servings'}: ${calculation.numberOfServings}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getCostTierColor(String tier) {
    switch (tier) {
      case CostTiers.low:
        return AppColors.success;
      case CostTiers.medium:
        return AppColors.warning;
      case CostTiers.high:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getCostTierLabel(String tier, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (tier) {
      case CostTiers.low:
        return l10n?.low ?? 'Low';
      case CostTiers.medium:
        return l10n?.medium ?? 'Medium';
      case CostTiers.high:
        return l10n?.high ?? 'High';
      default:
        return tier;
    }
  }
}

