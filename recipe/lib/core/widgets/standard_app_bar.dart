import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';

/// Standard AppBar widget for consistent styling across all pages
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final PreferredSizeWidget? bottom;

  const StandardAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.home);
                  }
                },
              ),
            )
          : showMenuButton
              ? Builder(
                  builder: (builderContext) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Colors.white),
                        onPressed: () {
                          if (onMenuPressed != null) {
                            onMenuPressed!();
                            return;
                          }
                          
                          // Try to open drawer using Scaffold.of
                          try {
                            Scaffold.of(builderContext).openDrawer();
                          } catch (e) {
                            // Fallback: find ScaffoldState in the widget tree
                            final scaffoldState = builderContext.findAncestorStateOfType<ScaffoldState>();
                            if (scaffoldState != null) {
                              scaffoldState.openDrawer();
                            }
                          }
                        },
                      ),
                    );
                  },
                )
              : null,
      title: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: subtitle != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              )
            : Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
      ),
      actions: actions != null
          ? actions!.map((action) {
              if (action is IconButton) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: action,
                );
              }
              // Return other widgets as-is (like Container, Consumer, etc.)
              return action;
            }).toList()
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        bottom != null ? kToolbarHeight + (bottom!.preferredSize.height) : kToolbarHeight,
      );
}

