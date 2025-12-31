import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor acepta los Términos y Condiciones'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).registerWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );

      if (mounted) {
        Logger.success('Registration successful', 'RegisterScreen');
        
        // Show success dialog with clear messaging
        final email = _emailController.text.trim();
        
        // Show snackbar notification that verification email was sent (after dialog)
        // This will be shown after the dialog is dismissed
        
        // Show success modal dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
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
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      '¡Cuenta Creada Exitosamente!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      'Tu cuenta ha sido creada exitosamente.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Important instruction
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Por favor verifica tu correo electrónico para continuar',
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
                    
                    // Email Verification Sent Alert Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withOpacity(0.15),
                            AppColors.success.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.mark_email_read_outlined,
                                  color: AppColors.success,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '¡Correo de Verificación Enviado!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Revisa tu bandeja de entrada ahora',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Enviamos un correo de verificación a:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Por favor verifica tu correo electrónico para continuar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Spam folder warning
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
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
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Si no encuentras el correo, revisa tu carpeta de spam o correo no deseado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Continue Button
                    CustomButton(
                      text: 'Continuar a Verificación',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Logger.info('Navigating to email verification screen for: $email', 'RegisterScreen');
                        
                        // Show snackbar notification that verification email was sent
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.mark_email_read_outlined,
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
                                        '¡Correo de Verificación Enviado!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Revisa tu bandeja de entrada en $email',
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
                        
                        context.go('${Routes.emailVerification}?email=${Uri.encodeComponent(email)}');
                      },
                      isLoading: false,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // Log the full error for debugging
      Logger.error('Registration error', e, null, 'RegisterScreen');
      if (mounted) {
        // Extract user-friendly error message
        String errorMessage = _getErrorMessage(e);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Get user-friendly error message from exception
  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'La contraseña es demasiado débil. Por favor usa una contraseña más fuerte (mínimo 6 caracteres).';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con esta dirección de correo electrónico.';
        case 'invalid-email':
          return 'La dirección de correo electrónico no es válida.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada. Por favor contacta al soporte.';
        case 'operation-not-allowed':
          return 'El registro con email y contraseña no está habilitado. Por favor contacta al soporte.';
        case 'invalid-credential':
          return 'Credenciales inválidas. Por favor verifica tu correo electrónico y contraseña.';
        case 'unauthorized-domain':
          return 'Este dominio de correo electrónico no está permitido.';
        case 'invalid-continue-uri':
        case 'unauthorized-continue-uri':
          return 'Error de configuración. Por favor contacta al soporte.';
        case 'network-request-failed':
          return 'Error de conexión. Por favor verifica tu internet e intenta de nuevo.';
        default:
          return e.message ?? 'Ocurrió un error durante el registro. Por favor intenta de nuevo.';
      }
    }
    
    // Handle Exception with Firebase error code format: "code: message"
    String errorMessage = e.toString();
    if (errorMessage.contains('Exception: ')) {
      errorMessage = errorMessage.replaceFirst('Exception: ', '');
    }
    
    // Extract Firebase error code if present (format: "code: message")
    if (errorMessage.contains(':') && errorMessage.length > 0) {
      final parts = errorMessage.split(':');
      if (parts.length >= 2) {
        final code = parts[0].trim();
        final message = parts.sublist(1).join(':').trim();
        
        // Handle specific Firebase error codes
        switch (code) {
          case 'operation-not-allowed':
            return 'El registro con email y contraseña no está habilitado. Ve a Firebase Console → Authentication → Sign-in method y habilita Email/Password.';
          case 'weak-password':
            return 'La contraseña es demasiado débil. Por favor usa una contraseña más fuerte (mínimo 6 caracteres).';
          case 'email-already-in-use':
            return 'Ya existe una cuenta con esta dirección de correo electrónico.';
          case 'invalid-email':
            return 'La dirección de correo electrónico no es válida.';
          case 'network-request-failed':
            return 'Error de conexión. Por favor verifica tu internet e intenta de nuevo.';
          default:
            // Return the user-friendly message part
            return message.isNotEmpty ? message : 'Ocurrió un error durante el registro. Por favor intenta de nuevo.';
        }
      }
    }
    
    if (errorMessage.contains('FirebaseException')) {
      return 'Error de conexión con Firebase. Por favor verifica tu conexión e intenta de nuevo.';
    }
    
    return errorMessage.isNotEmpty 
        ? errorMessage 
        : 'Ocurrió un error durante el registro. Por favor intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Logo with modern container
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'logo/logococinaentucasa.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Header
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete y comienza tu aventura culinaria',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray200.withOpacity(0.8),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name Field
                        CustomTextField(
                          label: 'Nombre Completo',
                          hint: 'Ingresa tu nombre completo',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                          validator: Validators.validateName,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Email Field
                        CustomTextField(
                          label: 'Correo Electrónico',
                          hint: 'Ingresa tu correo electrónico',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.validateEmail,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Password Field
                        CustomTextField(
                          label: 'Contraseña',
                          hint: 'Crea una contraseña',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.validateStrongPassword,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Confirm Password Field
                        CustomTextField(
                          label: 'Confirmar Contraseña',
                          hint: 'Vuelve a ingresar tu contraseña',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) => Validators.validatePasswordConfirm(
                            value,
                            _passwordController.text,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(),
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Terms and Conditions Checkbox
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _agreeToTerms ? AppColors.primary : AppColors.gray300,
                              width: _agreeToTerms ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _agreeToTerms = value ?? false;
                                          });
                                        },
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Acepto los ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Términos y Condiciones',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Register Button
                        CustomButton(
                          text: 'Crear Cuenta',
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                          icon: Icons.person_add_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

