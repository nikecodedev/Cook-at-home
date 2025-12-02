import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';

/// Admin route guard - redirects non-admin users
class AdminGuard {
  static bool canAccess(WidgetRef ref) {
    final userAsync = ref.read(currentUserProvider);
    return userAsync.when(
      data: (user) => user?.isAdmin ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  static Widget buildAdminRoute(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final userAsync = ref.watch(currentUserProvider);
        
        return userAsync.when(
          data: (user) {
            if (user?.isAdmin == true) {
              return child;
            }
            // Redirect to home if not admin
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(Routes.home);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access denied. Admin privileges required.'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(Routes.home);
            });
            return const Scaffold(
              body: Center(child: Text('Error loading user data')),
            );
          },
        );
      },
    );
  }
}

