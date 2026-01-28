import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/refill_alert_model.dart';
import '../../../../core/router/app_router.dart';

/// Widget to display refill alerts
class RefillAlertsWidget extends ConsumerWidget {
  const RefillAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final refillAlertService = ref.watch(refillAlertServiceProvider);
    final alertsAsync = ref.watch(
      StreamProvider<List<RefillAlert>>((ref) {
        return refillAlertService.streamActiveRefillAlerts(userId);
      }),
    );

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n?.refillAlerts ?? 'Refill Alerts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts.take(3).map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildAlertItem(context, ref, alert),
                  )),
              if (alerts.length > 3)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full alerts screen
                  },
                  child: Text(
                    'Ver ${alerts.length - 3} más',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlertItem(
    BuildContext context,
    WidgetRef ref,
    RefillAlert alert,
  ) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert.reason),
            size: 18,
            color: _getAlertColor(alert.reason),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.ingredientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (alert.currentQuantity != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${alert.currentQuantity!.toStringAsFixed(1)} ${alert.currentUnit ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (alert.priceIndex != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getAlertReasonText(alert.reason, l10n),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getAlertColor(alert.reason),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              try {
                await ref
                    .read(refillAlertServiceProvider)
                    .dismissRefillAlert(alert.userId, alert.id);
              } catch (e) {
                // Handle error silently
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String reason) {
    switch (reason) {
      case 'depletion':
        return Icons.warning_amber_rounded;
      case 'high_usage':
        return Icons.trending_up_rounded;
      case 'price_index':
        return Icons.local_offer_rounded;
      default:
        return Icons.shopping_cart_outlined;
    }
  }

  Color _getAlertColor(String reason) {
    switch (reason) {
      case 'depletion':
        return AppColors.error;
      case 'high_usage':
        return AppColors.warning;
      case 'price_index':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  String _getAlertReasonText(String reason, AppLocalizations? l10n) {
    switch (reason) {
      case 'depletion':
        return l10n?.lowStock ?? 'Low Stock';
      case 'high_usage':
        return l10n?.frequentlyUsed ?? 'Frequently Used';
      case 'price_index':
        return l10n?.goodPrice ?? 'Good Price';
      default:
        return reason;
    }
  }
}

