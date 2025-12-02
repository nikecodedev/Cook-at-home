import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/logger.dart';
import '../router/app_router.dart';

/// Splash screen widget that shows during app initialization
/// Includes watchdog timer to ensure app never freezes
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _maxTimeoutTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    
    // Watchdog timer - FORCE navigation after maximum 3 seconds (reduced from 5)
    // This ensures the app NEVER freezes on splash screen
    // Router should handle navigation before this, but this is the ultimate safety net
    _maxTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasNavigated) {
        Logger.warning('Splash screen watchdog: Forcing navigation after 3s timeout', 'SplashScreen');
        _hasNavigated = true;
        try {
          // Force navigation to login - router will handle auth state
          final router = GoRouter.of(context);
          router.go(Routes.login);
        } catch (e) {
          Logger.error('Error forcing navigation from splash screen', e, null, 'SplashScreen');
          // If router is not available, try to navigate using Navigator
          try {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          } catch (e2) {
            Logger.error('Failed to navigate from splash screen', e2, null, 'SplashScreen');
            // Last resort: try root navigator
            try {
              Navigator.of(context, rootNavigator: true).pushReplacementNamed(Routes.login);
            } catch (e3) {
              Logger.error('All navigation methods failed', e3, null, 'SplashScreen');
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _maxTimeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Monitor router changes - if we navigate away, mark as navigated
    // This prevents the watchdog from firing if router already navigated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final router = GoRouter.of(context);
          // If we're no longer on splash route, mark as navigated
          if (router.routerDelegate.currentConfiguration.uri.path != Routes.splash) {
            _hasNavigated = true;
            _maxTimeoutTimer?.cancel();
          }
        } catch (e) {
          // Ignore errors - router might not be ready yet
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'logo/logococinaentucasa.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if logo doesn't exist
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


