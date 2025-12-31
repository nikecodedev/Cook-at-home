import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailSent = false;
    });

    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
            _emailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Correo de restablecimiento enviado! Por favor revisa tu bandeja de entrada.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        
        // For user-not-found, show success message (security best practice)
        // Don't reveal that user doesn't exist
        if (errorMessage.toLowerCase().contains('user-not-found') ||
            errorMessage.toLowerCase().contains('no se encontró')) {
          setState(() {
            _emailSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Si existe una cuenta con este correo, recibirás un enlace para restablecer tu contraseña. Por favor revisa tu bandeja de entrada y carpeta de spam.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Ayuda',
                textColor: Colors.white,
                onPressed: () {
                  _showEmailHelpDialog(context);
                },
              ),
          ),
        );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                  '¿Olvidaste tu Contraseña?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _emailSent
                      ? 'Hemos enviado un enlace para restablecer tu contraseña a ${_emailController.text.trim()}. Por favor revisa tu correo electrónico y sigue las instrucciones para restablecer tu contraseña.'
                      : 'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Email Field
                  CustomTextField(
                    label: 'Correo Electrónico',
                    hint: 'Ingresa tu correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleResetPassword(),
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Reset Password Button
                  CustomButton(
                    text: 'Enviar Enlace de Restablecimiento',
                    onPressed: _handleResetPassword,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  // Success message
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
                                '¡Correo Enviado!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Por favor revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
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

                  // Back to Login Button
                  CustomButton(
                    text: 'Volver al Inicio de Sesión',
                    onPressed: () => context.go(Routes.login),
                  ),
                ],

                const SizedBox(height: 24),

                // Back to Login Link
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    child: Text(
                      'Volver al Inicio de Sesión',
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
      ),
    );
  }

  void _showEmailHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Ayuda con el Correo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Si no recibes el correo de restablecimiento:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(Icons.folder_special, 'Revisa tu carpeta de spam o correo no deseado'),
              _buildHelpItem(Icons.access_time, 'Espera unos minutos, el correo puede tardar en llegar'),
              _buildHelpItem(Icons.email_outlined, 'Verifica que ingresaste el correo correctamente'),
              _buildHelpItem(Icons.refresh, 'Intenta nuevamente después de unos minutos'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los correos de Firebase pueden tardar hasta 5 minutos en llegar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

