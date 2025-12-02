import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../repositories/auth_repository.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../core/widgets/splash_screen.dart';
import '../../core/utils/logger.dart';
import '../../core/theme/app_colors.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/pantry/presentation/screens/pantry_list_screen.dart';
import '../../features/pantry/presentation/screens/pantry_edit_screen.dart';
import '../../models/pantry_item_model.dart';
import '../../features/recipes/presentation/screens/recipe_list_screen.dart';
import '../../features/recipes/presentation/screens/recipe_detail_screen.dart';
import '../../features/recipes/presentation/screens/recipe_add_screen.dart';
import '../../models/recipe_model.dart';
import '../../features/shopping/presentation/screens/shopping_list_screen.dart';
import '../../features/shopping/presentation/screens/shopping_lists_screen.dart';
import '../../models/shopping_list_model.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_recipes_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_feedback_screen.dart';
import '../../features/landing/presentation/screens/landing_page.dart';
import 'admin_guard.dart';

/// Route names
class Routes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String pantry = '/pantry';
  static const String pantryEdit = '/pantry/edit';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/detail';
  static const String recipeAdd = '/recipes/add';
  static const String recipeEdit = '/recipes/edit';
  static const String shoppingList = '/shopping-list';
  static const String shoppingLists = '/shopping-lists';
  static const String feedback = '/feedback';
  static const String adminDashboard = '/admin';
  static const String adminRecipes = '/admin/recipes';
  static const String adminUsers = '/admin/users';
  static const String adminCategories = '/admin/categories';
  static const String adminFeedback = '/admin/feedback';
}

/// Perform redirect logic with proper timeout handling
/// This function is designed to NEVER hang - it always returns quickly
Future<String?> _performRedirect(
  BuildContext context,
  GoRouterState state,
  AsyncValue<User?> authState,
  FirebaseAuthService authService,
  AuthRepository authRepository,
) async {
  try {
    // If on splash screen, wait a minimal moment then redirect (with strict timeout)
    if (state.matchedLocation == Routes.splash) {
      try {
        await Future.delayed(const Duration(milliseconds: 300))
            .timeout(const Duration(milliseconds: 500));
      } catch (e) {
        // Ignore timeout, proceed immediately
      }
    }

    // Check auth state with aggressive timeout - NEVER wait more than 1 second
    User? firebaseUser;
    try {
      firebaseUser = await Future.value(authService.currentUser)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      // Continue with null user - don't wait
      Logger.warning('Quick timeout checking Firebase user, proceeding', 'Router');
    }

    // Get auth state value immediately (don't wait for async)
    final authStateValue = authState.value;
    final isLoggedIn = authStateValue != null || firebaseUser != null;
    
    final isGoingToLogin = state.matchedLocation == Routes.login;
    final isGoingToRegister = state.matchedLocation == Routes.register;
    final isGoingToForgotPassword =
        state.matchedLocation == Routes.forgotPassword;
    final isGoingToEmailVerification =
        state.matchedLocation == Routes.emailVerification;
    final isGoingToSplash = state.matchedLocation == Routes.splash;
    final isGoingToLanding = state.matchedLocation == Routes.landing;

    // Handle splash screen redirect - ALWAYS resolve quickly
    // This is critical - splash screen must NEVER hang
    if (isGoingToSplash) {
      // Use minimal delay for splash screen animation, then redirect immediately
      try {
        await Future.delayed(const Duration(milliseconds: 500))
            .timeout(const Duration(milliseconds: 800));
      } catch (e) {
        // Ignore timeout - proceed immediately
      }
      
      // If logged in, check email verification with strict timeout
      if (isLoggedIn) {
        bool isEmailVerified = false;
        try {
          // Use very short timeout - don't wait more than 500ms
          await authRepository.reloadUser()
              .timeout(const Duration(milliseconds: 500));
          isEmailVerified = authRepository.isEmailVerified;
        } catch (e) {
          // If timeout or error, default to not verified and proceed
          Logger.warning('Quick timeout checking email verification, defaulting to false', 'Router');
          isEmailVerified = false;
        }
        
        if (isEmailVerified) {
          return Routes.home;
        } else {
          final user = authStateValue ?? firebaseUser;
          if (user?.email != null) {
            return '${Routes.emailVerification}?email=${Uri.encodeComponent(user!.email!)}';
          }
          // If no email, go to login
          return Routes.login;
        }
      }
      // Not logged in - go to login immediately (no delay)
      return Routes.login;
    }

    // Check email verification screen access
    if (isGoingToEmailVerification) {
      // If logged in, check if email is verified - if so, redirect to home
      if (isLoggedIn) {
        try {
          // Quick check without reload to avoid delays
          final isEmailVerified = authRepository.isEmailVerified;
          if (isEmailVerified) {
            Logger.info('Email verified, redirecting from verification screen to home', 'Router');
            return Routes.home;
          }
        } catch (e) {
          Logger.warning('Error checking email verification in router: $e', 'Router');
        }
      }
      // Allow navigation - user might have just registered or needs to verify
      return null;
    }

    // Always allow access to landing page
    if (isGoingToLanding) {
      return null;
    }

    // If not logged in and not going to auth screens, redirect to login
    if (!isLoggedIn &&
        !isGoingToLogin &&
        !isGoingToRegister &&
        !isGoingToForgotPassword &&
        !isGoingToEmailVerification &&
        !isGoingToLanding) {
      return Routes.login;
    }

    // If logged in, check email verification
    if (isLoggedIn) {
      // Always allow navigation to email verification screen (needed after registration)
      if (isGoingToEmailVerification) {
        return null; // Allow navigation
      }
      
      // Reload user to get latest verification status (important when coming from email link)
      // Use aggressive timeout - don't wait more than 1 second
      bool isEmailVerified = false;
      try {
        await authRepository.reloadUser()
            .timeout(const Duration(milliseconds: 800));
        isEmailVerified = authRepository.isEmailVerified;
      } catch (e) {
        // If timeout or error, use current state or default to false
        Logger.warning('Quick timeout reloading user, using current state', 'Router');
        try {
          isEmailVerified = authRepository.isEmailVerified;
        } catch (e2) {
          // If even getting current state fails, default to false
          isEmailVerified = false;
        }
      }
      
      // If email is verified, redirect to home if on auth screens
      if (isEmailVerified) {
        if (isGoingToLogin || isGoingToForgotPassword || isGoingToRegister) {
          return Routes.home;
        }
        // Allow staying on other screens
      } else {
        // If email is not verified
        // Allow staying on register screen (for navigation to email verification)
        if (isGoingToRegister) {
          return null; // Allow navigation to register screen
        }
        // Allow access to login and forgot password for sign out
        if (isGoingToLogin || isGoingToForgotPassword) {
          return null; // Allow navigation - login screen will handle verification check
        }
        // For other pages, redirect to verification screen
        final user = authStateValue ?? firebaseUser;
        if (user?.email != null) {
          return '${Routes.emailVerification}?email=${Uri.encodeComponent(user!.email!)}';
        }
      }
    }

    // No redirect needed
    return null;
  } catch (e) {
    Logger.error('Error in redirect logic', e, null, 'Router');
    // On any error, redirect to login to prevent hanging
    if (state.matchedLocation == Routes.splash) {
      return Routes.login;
    }
    return null;
  }
}

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = FirebaseAuthService();
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) async {
      // Maximum timeout for entire redirect logic - prevent infinite hanging
      // Use aggressive 3-second timeout to ensure app never freezes
      try {
        return await _performRedirect(context, state, authState, authService, authRepository)
            .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Logger.warning('Redirect timeout reached (3s), forcing navigation to login', 'Router');
            // ALWAYS force navigation to login if timeout - never return null
            if (state.matchedLocation == Routes.splash) {
              return Routes.login;
            }
            // For other routes, allow navigation (return null)
            return null;
          },
        );
      } catch (e) {
        Logger.error('Critical error in redirect, forcing login', e, null, 'Router');
        // ALWAYS have a fallback - go to login if on splash
        if (state.matchedLocation == Routes.splash) {
          return Routes.login;
        }
        // For other routes, allow navigation
        return null;
      }
    },
    errorBuilder: (context, state) {
      Logger.error('Router error', state.error, null, 'Router');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Error de Navegación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor intenta de nuevo',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Ir al Inicio de Sesión'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: Routes.landing,
        name: 'landing',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LandingPage(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: Routes.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: EmailVerificationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pantry,
        name: 'pantry',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PantryListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pantryEdit,
        name: 'pantry-edit',
        pageBuilder: (context, state) {
          final extra = state.extra as PantryItem?;
          return MaterialPage(
            key: state.pageKey,
            child: PantryEditScreen(item: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.recipes,
        name: 'recipes',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RecipeListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.recipeDetail,
        name: 'recipe-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Recipe;
          return MaterialPage(
            key: state.pageKey,
            child: RecipeDetailScreen(recipe: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.recipeAdd,
        name: 'recipe-add',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RecipeAddScreen(),
        ),
      ),
      GoRoute(
        path: Routes.recipeEdit,
        name: 'recipe-edit',
        pageBuilder: (context, state) {
          final extra = state.extra as Recipe;
          return MaterialPage(
            key: state.pageKey,
            child: RecipeAddScreen(recipe: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.shoppingLists,
        name: 'shopping-lists',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ShoppingListsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.shoppingList,
        name: 'shopping-list',
        pageBuilder: (context, state) {
          final extra = state.extra as ShoppingList;
          return MaterialPage(
            key: state.pageKey,
            child: ShoppingListScreen(shoppingList: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.feedback,
        name: 'feedback',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FeedbackScreen(),
        ),
      ),
      // Admin Routes (with access control)
      GoRoute(
        path: Routes.adminDashboard,
        name: 'admin-dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminRecipes,
        name: 'admin-recipes',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminRecipesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminUsers,
        name: 'admin-users',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminUsersScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminCategories,
        name: 'admin-categories',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminCategoriesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminFeedback,
        name: 'admin-feedback',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AdminGuard.buildAdminRoute(
            context,
            state,
            const AdminFeedbackScreen(),
          ),
        ),
      ),
    ],
  );
});
