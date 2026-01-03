import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../widgets/modern_recipe_card.dart';

/// Modern, clean, user-friendly home page
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      drawer: _buildDrawer(context, isMobile),
      appBar: StandardAppBar(
        title: 'Cocina en tu Casa',
        showBackButton: false,
        showMenuButton: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.transparent,
          indicatorWeight: 0,
          indicator: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'Inicio'),
            Tab(text: 'Explorar'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.white),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Tab Content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // Welcome Section
                  _buildWelcomeSection(context, isMobile, isTablet, user?.displayName),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions Grid
                  _buildQuickActionsGrid(context, isMobile, isTablet),
                  
                  const SizedBox(height: 40),
                  
                  // Footer
                  _buildFooter(context, isMobile, isTablet),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Explore Tab Content
          SafeArea(
            child: _buildExploreTab(context, isMobile, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isMobile, bool isTablet, String? userName) {
    final greeting = _getGreeting();
    final displayName = userName?.split(' ').first ?? 'Usuario';
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.03),
            AppColors.primary.withOpacity(0.01),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¿Qué vamos a cocinar hoy?',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  Widget _buildDrawer(BuildContext context, bool isMobile) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Status bar area - Red section (#fa4e3d)
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color(0xFFFA4E3D),
          ),
          // Drawer Header - Red section (no border, no white space)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cocina en tu Casa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Drawer content with SafeArea
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildDrawerItem(
                          context,
                          Icons.home_rounded,
                          'Inicio',
                          () {
                            Navigator.pop(context);
                            context.go(Routes.home);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.kitchen_rounded,
                          'Mi Despensa',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.pantry);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.restaurant_menu_rounded,
                          'Recetas',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.recipes);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.shopping_cart_rounded,
                          'Listas de Compras',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.shoppingLists);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.auto_awesome_rounded,
                          'Sugerencias',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.suggestedRecipes);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.straighten_rounded,
                          'Convertidor de Medidas',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.measurementConverter);
                          },
                        ),
                        Divider(
                          height: 32,
                          color: AppColors.gray200,
                          thickness: 1,
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.person_outline_rounded,
                          'Perfil',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.profile);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          Icons.feedback_outlined,
                          'Comentarios',
                          () {
                            Navigator.pop(context);
                            context.push(Routes.feedback);
                          },
                        ),
                        Divider(
                          height: 32,
                          color: AppColors.gray200,
                          thickness: 1,
                        ),
                        // Logout Button - Last item at bottom
                        _buildDrawerItem(
                          context,
                          Icons.logout_rounded,
                          'Cerrar Sesión',
                          () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Close drawer first
      Navigator.pop(context);
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Cerrando sesión...'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Sign out
      await ref.read(authControllerProvider.notifier).signOut();
      
      if (mounted) {
        Logger.success('User signed out successfully', 'HomeScreen');
        // Navigate to login screen
        context.go(Routes.login);
      }
    } catch (e) {
      Logger.error('Logout failed', e, null, 'HomeScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isMobile, bool isTablet) {
    final actions = [
      {
        'icon': Icons.kitchen_rounded,
        'title': 'Mi Despensa',
        'subtitle': 'Gestionar',
        'route': Routes.pantry,
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.primaryLight],
        'bgGradient': [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.03)],
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Recetas',
        'subtitle': 'Ver todas las recetas',
        'route': Routes.recipes,
        'color': AppColors.oliveGreen,
        'gradient': [AppColors.oliveGreen, const Color(0xFF8FA83A)],
        'bgGradient': [AppColors.oliveGreen.withOpacity(0.08), AppColors.oliveGreen.withOpacity(0.03)],
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'title': 'Compras',
        'subtitle': 'Listas de compras',
        'route': Routes.shoppingLists,
        'color': const Color(0xFF2196F3),
        'gradient': [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        'bgGradient': [const Color(0xFF2196F3).withOpacity(0.08), const Color(0xFF2196F3).withOpacity(0.03)],
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Sugerencias',
        'subtitle': 'Ideas de recetas',
        'route': Routes.suggestedRecipes,
        'color': AppColors.cornYellow,
        'gradient': [AppColors.cornYellow, const Color(0xFFFFD966)],
        'bgGradient': [AppColors.cornYellow.withOpacity(0.08), AppColors.cornYellow.withOpacity(0.03)],
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 4),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 0.95 : 1.0,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(
                context,
                action['icon'] as IconData,
                action['title'] as String,
                action['subtitle'] as String,
                action['route'] as String,
                action['gradient'] as List<Color>,
                action['bgGradient'] as List<Color>,
                isMobile,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
    List<Color> gradient,
    List<Color> bgGradient,
    bool isMobile,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (context.mounted) {
            context.push(route);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 22 : 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgGradient,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: gradient[0].withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 64 : 72,
                height: isMobile ? 64 : 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 32 : 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildFeaturedSection(BuildContext context, bool isMobile, bool isTablet) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Recetas Destacadas',
  //               style: TextStyle(
  //                 fontSize: isMobile ? 20 : 24,
  //                 fontWeight: FontWeight.bold,
  //                 color: const Color(0xFF212121),
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () => context.push(Routes.recipes),
  //               child: const Text(
  //                 'Ver Todas',
  //                 style: TextStyle(
  //                   color: Color(0xFFE63946),
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 const Color(0xFFE63946).withOpacity(0.1),
  //                 const Color(0xFFFF6B6B).withOpacity(0.05),
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(24),
  //           ),
  //           child: Column(
  //             children: [
  //               Container(
  //                 width: 80,
  //                 height: 80,
  //                 decoration: BoxDecoration(
  //                   gradient: const LinearGradient(
  //                     colors: [AppColors.primary, AppColors.primaryLight],
  //                   ),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: const Icon(
  //                   Icons.restaurant_menu_rounded,
  //                   color: Colors.white,
  //                   size: 40,
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 'Descubre Nuevas Recetas',
  //                 style: TextStyle(
  //                   fontSize: isMobile ? 18 : 20,
  //                   fontWeight: FontWeight.bold,
  //                   color: const Color(0xFF212121),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Obtén sugerencias de recetas personalizadas basadas en tu despensa',
  //                 style: TextStyle(
  //                   fontSize: isMobile ? 14 : 15,
  //                   color: const Color(0xFF757575),
  //                   height: 1.5,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 20),
  //               ElevatedButton(
  //                 onPressed: () => context.push(Routes.recipes),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFFE63946),
  //                   foregroundColor: Colors.white,
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: isMobile ? 32 : 40,
  //                     vertical: 16,
  //                   ),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   elevation: 0,
  //                 ),
  //                 child: const Text(
  //                   'Explorar Recetas',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.w600,
  //                     fontSize: 15,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatsSection(BuildContext context, bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              Icons.kitchen_rounded,
              'Artículos de Despensa',
              '0',
              const Color(0xFFE63946),
              isMobile,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.restaurant_menu_rounded,
              'Recetas',
              '0',
              const Color(0xFF4CAF50),
              isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 140 : 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 56 : 64,
            height: isMobile ? 56 : 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cocina en tu Casa',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cocina de manera inteligente con lo que tienes',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab(BuildContext context, bool isMobile, bool isTablet) {
    final recipesAsync = ref.watch(allRecipesStreamProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explorar',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Descubre nuevas recetas y funcionalidades',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Quick Links Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildExploreCard(
                        context,
                        Icons.restaurant_menu_rounded,
                        'Todas las Recetas',
                        AppColors.primary,
                        () => context.push(Routes.recipes),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildExploreCard(
                        context,
                        Icons.auto_awesome_rounded,
                        'Sugerencias',
                        AppColors.cornYellow,
                        () => context.push(Routes.suggestedRecipes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildExploreCard(
                        context,
                        Icons.straighten_rounded,
                        'Convertidor',
                        const Color(0xFF2196F3),
                        () => context.push(Routes.measurementConverter),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildExploreCard(
                        context,
                        Icons.feedback_outlined,
                        'Comentarios',
                        AppColors.oliveGreen,
                        () => context.push(Routes.feedback),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Featured Recipes Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recetas Destacadas',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Recipes List
          recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay recetas disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega tu primera receta para comenzar',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(Routes.recipeAdd),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Receta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show up to 6 featured recipes (most recent)
              final featuredRecipes = recipes.take(6).toList();

              return Column(
                children: [
                  ...featuredRecipes.map((recipe) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 20 : (isTablet ? 32 : 48),
                        right: isMobile ? 20 : (isTablet ? 32 : 48),
                        bottom: 16,
                      ),
                      child: ModernRecipeCard(
                        recipe: recipe,
                        onTap: () {
                          context.push(Routes.recipeDetail, extra: recipe);
                        },
                      ),
                    );
                  }),
                  if (recipes.length > 6)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
                      ),
                      child: OutlinedButton(
                        onPressed: () => context.push(Routes.recipes),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: Text(
                          'Ver Todas las Recetas (${recipes.length})',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar recetas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    final gradient = [
      color,
      color.withOpacity(0.8),
    ];
    final bgGradient = [
      color.withOpacity(0.08),
      color.withOpacity(0.03),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgGradient,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
