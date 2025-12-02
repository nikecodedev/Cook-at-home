import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification banner widget that displays in-app notifications
class NotificationBanner extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (onDismiss != null) {
          onDismiss!();
        } else {
          ref.read(notificationStateProvider.notifier).removeNotification(notification.id);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(notification.type),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getBorderColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(String? type) {
    switch (type) {
      case 'pantry_expiry':
        return AppColors.warning;
      case 'recipe_suggestion':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  Color _getBackgroundColor(String? type) {
    switch (type) {
      case 'pantry_expiry':
        return AppColors.warning;
      case 'recipe_suggestion':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'pantry_expiry':
        return Icons.warning_rounded;
      case 'recipe_suggestion':
        return Icons.lightbulb_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

/// Notification overlay that shows notifications at the top of the screen
class NotificationOverlay extends ConsumerWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);
    final unreadNotifications = notificationState.notifications
        .where((n) => !n.isRead)
        .take(3)
        .toList();

    if (unreadNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Column(
        children: unreadNotifications.map((notification) {
          return NotificationBanner(
            notification: notification,
            onTap: () {
              ref.read(notificationStateProvider.notifier).markAsRead(notification.id);
              // Navigate based on notification type
              _handleNotificationTap(context, notification);
            },
          );
        }).toList(),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case 'pantry_expiry':
        // Navigate to pantry screen
        // context.push(Routes.pantry);
        break;
      case 'recipe_suggestion':
        // Navigate to suggested recipes
        // context.push(Routes.recipes);
        break;
      default:
        break;
    }
  }
}

