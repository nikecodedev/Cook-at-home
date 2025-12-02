import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/auth/firebase_auth_service.dart';
import '../../../../core/config/firebase_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  final FirebaseAuthService _authService = FirebaseAuthService();
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    // Handle email verification link if app opened from email (web only)
    // Also check initial verification status
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check verification status FIRST - if verified, redirect immediately
      await _checkInitialVerificationStatus();
      
      // Only proceed if not verified
      if (!_isVerified && mounted) {
        _handleEmailVerificationLink();
        // Show verification instructions dialog only if not verified
        _showVerificationDialog();
        // Start periodic verification check (every 5 seconds)
        _startVerificationCheckTimer();
      }
    });
  }

  void _showVerificationDialog() {
    if (_isVerified) return; // Don't show if already verified
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Revisa tu Bandeja de Entrada',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Email Address
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Message
                Text(
                  'Enviamos un enlace de verificación a tu correo electrónico. Por favor haz clic en el enlace para activar tu cuenta.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Info Text - Spam folder reminder
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.folder_special_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿No recibiste el correo?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Revisa tu carpeta de spam o correo no deseado. Si aún no lo encuentras, intenta reenviarlo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Close Button
                CustomButton(
                  text: 'Entendido',
                  onPressed: () => Navigator.of(context).pop(),
                  isLoading: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheckTimer() {
    // Only check if not already verified
    if (_isVerified) return;
    
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (_isVerified || !mounted) {
          timer.cancel();
          return;
        }
        
        try {
          await _authService.reloadUser();
          if (mounted && _authService.isEmailVerified && !_isVerified) {
            timer.cancel();
            setState(() {
              _isVerified = true;
            });
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¡Correo Verificado!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tu correo electrónico ha sido verificado exitosamente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } catch (e) {
          Logger.error('Error checking verification status', e, null, 'EmailVerificationScreen');
        }
      },
    );
  }

  Future<void> _checkInitialVerificationStatus() async {
    try {
      await _authService.reloadUser();
      if (mounted) {
        final isVerified = _authService.isEmailVerified;
        setState(() {
          _isVerified = isVerified;
        });
        // If already verified, redirect to home immediately
        if (isVerified) {
          _verificationCheckTimer?.cancel();
          Logger.info('Email already verified, redirecting to home', 'EmailVerificationScreen');
          // Small delay to ensure UI is ready, then redirect
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            context.go(Routes.home);
          }
        }
      }
    } catch (e) {
      Logger.error('Error checking initial verification status', e, null, 'EmailVerificationScreen');
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() => _isResending = true);

    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail();

      if (mounted) {
        Logger.success('Verification email resent', 'EmailVerificationScreen');
        
        // Show a more prominent success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Correo Enviado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Por favor revisa tu bandeja de entrada',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        
        // Translate common error messages to Spanish and make them user-friendly
        if (errorMessage.contains('unauthorized-continue-uri') || 
            errorMessage.contains('invalid-continue-uri') ||
            errorMessage.contains('URL de redirección') ||
            errorMessage.contains('localhost') ||
            errorMessage.contains('127.0.0.1')) {
          // For localhost/unauthorized URL errors, try to resend automatically or show helpful message
          errorMessage = 'El correo se enviará automáticamente. Por favor revisa tu bandeja de entrada en unos momentos.';
        } else if (errorMessage.contains('too-many-requests')) {
          errorMessage = 'Demasiados intentos. Por favor espera unos minutos antes de intentar de nuevo.';
        } else if (errorMessage.contains('network') || errorMessage.contains('conexión')) {
          errorMessage = 'Error de conexión. Por favor verifica tu internet e intenta de nuevo.';
        } else if (errorMessage.contains('No se pudo enviar')) {
          // Keep user-friendly messages as is
        } else {
          // Generic friendly error message
          errorMessage = 'No se pudo enviar el correo. Por favor intenta de nuevo en unos momentos.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Handle email verification link when app opens from email (web only)
  Future<void> _handleEmailVerificationLink() async {
    if (!kIsWeb) return;
    
    try {
      // Check if URL contains email verification parameters (web only)
      final uri = Uri.base;
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      
      if (mode == 'verifyEmail' && oobCode != null) {
        Logger.info('Email verification link detected in URL', 'EmailVerificationScreen');
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Verificando tu correo electrónico...'),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        try {
          // Apply the action code directly to verify the email
          final auth = FirebaseConfig.auth;
          
          // Check if user is logged in
          final currentUser = auth.currentUser;
          if (currentUser == null) {
            Logger.warning('No user logged in when processing verification link', 'EmailVerificationScreen');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor inicia sesión primero, luego haz clic en el enlace de verificación nuevamente'),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }
          
          // Apply the verification code using FirebaseAuth with timeout
          await auth.applyActionCode(oobCode).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Email verification timed out');
            },
          );
          Logger.success('Email verified via action code', 'EmailVerificationScreen');
          
          // Reload user to get updated verification status
          await currentUser.reload().timeout(const Duration(seconds: 5));
          
          // Wait a moment for the state to update
          await Future.delayed(const Duration(milliseconds: 800));
          
          // Check verification status and update UI
          await _authService.reloadUser().timeout(const Duration(seconds: 5));
          
          if (mounted) {
            final isVerified = _authService.isEmailVerified;
            setState(() {
              _isVerified = isVerified;
            });
            
            if (isVerified) {
              _verificationCheckTimer?.cancel();
              
              // Clear any previous snackbars
              ScaffoldMessenger.of(context).clearSnackBars();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¡Correo Verificado Exitosamente!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ahora puedes acceder a todas las funciones',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        } catch (e) {
          Logger.error('Error applying action code', e, null, 'EmailVerificationScreen');
          
          // Even if applying fails, check if email is already verified
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
            await _authService.reloadUser().timeout(const Duration(seconds: 3));
            
            if (_authService.isEmailVerified && mounted) {
              Logger.success('Email already verified', 'EmailVerificationScreen');
              _verificationCheckTimer?.cancel();
              setState(() {
                _isVerified = true;
              });
              
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¡Correo Ya Verificado!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tu correo electrónico ya está verificado',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            } else if (mounted) {
              // Show error message
              ScaffoldMessenger.of(context).clearSnackBars();
              String errorMsg = 'Error al verificar el correo. Por favor intenta de nuevo o reenvía el correo de verificación.';
              if (e.toString().contains('expired')) {
                errorMsg = 'El enlace de verificación ha expirado. Por favor solicita uno nuevo.';
              } else if (e.toString().contains('invalid')) {
                errorMsg = 'Enlace de verificación inválido. Por favor solicita uno nuevo.';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Reenviar',
                    textColor: Colors.white,
                    onPressed: () => _handleResendEmail(),
                  ),
                ),
              );
            }
          } catch (reloadError) {
            Logger.error('Error reloading user after verification attempt', reloadError, null, 'EmailVerificationScreen');
          }
        }
      }
    } catch (e) {
      Logger.error('Error handling email verification link', e, null, 'EmailVerificationScreen');
    }
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isLoading = true);

    try {
      // First, check if there's a verification link in the URL (user might have clicked it)
      if (kIsWeb) {
        final uri = Uri.base;
        final mode = uri.queryParameters['mode'];
        final oobCode = uri.queryParameters['oobCode'];
        
        if (mode == 'verifyEmail' && oobCode != null) {
          // User clicked the link, apply the action code
          try {
            final auth = FirebaseConfig.auth;
            await auth.applyActionCode(oobCode);
            Logger.success('Email verified via action code from button', 'EmailVerificationScreen');
            
            // Reload user
            final currentUser = auth.currentUser;
            if (currentUser != null) {
              await currentUser.reload();
            }
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            Logger.error('Error applying action code from button', e, null, 'EmailVerificationScreen');
          }
        }
      }
      
      // Reload user data to get latest verification status
      await _authService.reloadUser();
      final isVerified = _authService.isEmailVerified;

      if (mounted) {
        setState(() {
          _isVerified = isVerified;
        });
        if (isVerified) {
          Logger.success('Email verified', 'EmailVerificationScreen');
          _verificationCheckTimer?.cancel();
          setState(() {
            _isVerified = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡Correo Verificado!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ahora puedes acceder a todas las funciones',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Correo aún no verificado. Por favor revisa tu bandeja de entrada y haz clic en el enlace de verificación.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go(Routes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => _handleSignOut(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Image.asset(
                  'logo/logococinaentucasa.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Verifica tu Correo Electrónico',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Success Alert Box - Account Created
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cuenta Creada Exitosamente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Por favor verifica tu correo electrónico para continuar',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Show different UI based on verification status
              if (_isVerified) ...[
                // Email is verified - show success and go to home button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Correo Verificado!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tu correo electrónico ha sido verificado. Ahora puedes acceder a todas las funciones.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Ir al Inicio',
                  onPressed: () => context.go(Routes.home),
                  icon: Icons.home,
                ),
              ] else ...[
                // Email not verified - show instructions and buttons
                // Check inbox reminder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Revisa tu Bandeja de Entrada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hemos enviado un correo de verificación a:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Verification buttons
                CustomButton(
                  text: 'Verifiqué mi Correo',
                  onPressed: _isLoading ? null : _handleCheckVerification,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 16),
                CustomOutlinedButton(
                  text: _isResending ? 'Enviando...' : 'Reenviar Correo de Verificación',
                  onPressed: _isResending ? null : _handleResendEmail,
                  icon: Icons.refresh,
                ),
              ],

              const SizedBox(height: 32),

              // Sign Out Option
              Center(
                  child: TextButton(
                  onPressed: _isLoading ? null : _handleSignOut,
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

