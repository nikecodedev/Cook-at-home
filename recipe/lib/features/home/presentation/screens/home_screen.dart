import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

/// Modern, clean, user-friendly home page
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: _buildDrawer(context, isMobile),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(context, isMobile, isTablet, user?.displayName),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Welcome Section
                    _buildWelcomeSection(context, isMobile, isTablet, user?.displayName),
                    
                    const SizedBox(height: 40),
                    
                    // Quick Actions Grid
                    _buildQuickActionsGrid(context, isMobile, isTablet),
                    
                    const SizedBox(height: 40),
                    
                    // Footer
                    _buildFooter(context, isMobile, isTablet),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isMobile, bool isTablet, String? userName) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
        vertical: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE63946), Color(0xFFFF4757)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE63946).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: isMobile ? 44 : 52,
                height: isMobile ? 44 : 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Cocina en tu Casa',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Action Buttons
          Row(
            children: [
              Builder(
                builder: (context) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(Routes.profile),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFE63946).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE63946), Color(0xFFFF4757)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE63946).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $displayName',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué vamos a cocinar hoy?',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC143C), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                      context.push(Routes.recipes);
                    },
                  ),
                  const Divider(height: 32),
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
                  const Divider(height: 32),
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
            
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child:               const Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF212121),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
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
        'subtitle': 'Gestionar ingredientes',
        'route': Routes.pantry,
        'color': const Color(0xFFE63946),
        'gradient': [const Color(0xFFE63946), const Color(0xFFFF4757)],
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Recetas',
        'subtitle': 'Ver todas las recetas',
        'route': Routes.recipes,
        'color': const Color(0xFF4CAF50),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'title': 'Compras',
        'subtitle': 'Listas de compras',
        'route': Routes.shoppingLists,
        'color': const Color(0xFF2196F3),
        'gradient': [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Sugerencias',
        'subtitle': 'Ideas de recetas',
        'route': Routes.recipes,
        'color': const Color(0xFFFF9800),
        'gradient': [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 4),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 28 : 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                  height: 1.3,
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
  //                     colors: [Color(0xFFE63946), Color(0xFFFF4757)],
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE63946).withOpacity(0.05),
            const Color(0xFFFF4757).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE63946).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE63946), Color(0xFFFF4757)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cocina en tu Casa',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cocina de manera inteligente con lo que tienes',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
