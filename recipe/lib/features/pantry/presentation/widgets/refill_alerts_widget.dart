import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/refill_alert_model.dart';
import '../../../../core/router/app_router.dart';

/// Provider for streaming refill alerts
final refillAlertsStreamProvider = StreamProvider.family<List<RefillAlert>, String>((ref, userId) {
  final service = ref.watch(refillAlertServiceProvider);
  return service.streamActiveRefillAlerts(userId);
});

/// Widget to display refill alerts
class RefillAlertsWidget extends ConsumerWidget {
  const RefillAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return _buildEmptyState(l10n);
    }

    final alertsAsync = ref.watch(refillAlertsStreamProvider(userId));

    return alertsAsync.when(
      loading: () => _buildLoadingSkeleton(),
      error: (error, _) => _buildEmptyState(l10n),
      data: (alerts) {
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
                  const Text(
                    'Alertas de Reabastecimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No hay alertas en este momento. Las alertas aparecerán cuando un ingrediente esté bajo, se use con frecuencia o haya buena oferta.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                )
              else ...[
                ...alerts.take(3).map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildAlertItem(context, ref, alert),
                    )),
                if (alerts.length > 3)
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Ver ${alerts.length - 3} más',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 160,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
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
              const Text(
                'Alertas de Reabastecimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay alertas en este momento. Las alertas aparecerán cuando un ingrediente esté bajo, se use con frecuencia o haya buena oferta.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
        return l10n?.lowStock ?? 'Stock Bajo';
      case 'high_usage':
        return l10n?.frequentlyUsed ?? 'Uso Frecuente';
      case 'price_index':
        return l10n?.goodPrice ?? 'Buen Precio';
      default:
        return reason;
    }
  }
}

