import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/config/firebase_config.dart';
import '../../core/utils/logger.dart';

/// Firebase Authentication Service
/// Handles user authentication operations
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseConfig.auth;
  
  // Initialize GoogleSignIn with client ID for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web, client ID is read from meta tag in index.html
    // For Android/iOS, it's configured in Firebase Console
    scopes: ['email', 'profile'],
  );

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Register with email and password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Send email verification IMMEDIATELY after user creation
      final user = userCredential.user;
      if (user != null && user.email != null) {
        Logger.info('Sending verification email immediately to: ${user.email}', 'FirebaseAuthService');
        
        // Send email immediately - Firebase handles user creation synchronously
        // No delay needed as Firebase Auth processes user creation instantly
        
        // Send email verification with actionCodeSettings for email template customization
        // 
        // ⚠️ CRITICAL: Email templates MUST be configured in Firebase Console!
        // 
        // Quick Setup:
        // 1. Firebase Console > Authentication > Templates > Email address verification
        // 2. Subject: "Verifica tu correo electrónico - Cocina en tu Casa"
        // 3. Sender name: "Cocina en tu Casa"
        // 4. Copy HTML from: docs/email_templates/verification_email.html
        // 5. Paste and Save
        // 
        // See docs/EMAIL_SETUP_STEP_BY_STEP.md for detailed instructions.
        try {
          ActionCodeSettings? actionCodeSettings;
          
          // IMPORTANT: The URL must be in Firebase Console > Authentication > Settings > Authorized domains
          // For mobile apps, we use the Firebase auth domain which is always authorized
          // For web, we use the current origin (must be added to authorized domains)
          
          if (kIsWeb) {
            // For web, check if it's localhost - if so, try without actionCodeSettings first
            final baseUrl = Uri.base.origin;
            final isLocalhost = baseUrl.contains('localhost') || 
                               baseUrl.contains('127.0.0.1') || 
                               baseUrl.contains('0.0.0.0');
            
            if (isLocalhost) {
              // For localhost, try sending without actionCodeSettings first (Firebase defaults)
              // This avoids authorization issues with localhost URLs
              bool emailSent = false;
              try {
                Logger.info('Localhost detected, sending email without actionCodeSettings', 'FirebaseAuthService');
                await user.sendEmailVerification(); // Send without actionCodeSettings
                Logger.success('Verification email sent successfully (default settings) to ${user.email}', 'FirebaseAuthService');
                emailSent = true;
              } catch (defaultError) {
                Logger.warning('Default email send failed for localhost, trying with Firebase auth domain: $defaultError', 'FirebaseAuthService');
                // Fallback: use Firebase auth domain instead of localhost
                final authDomain = _auth.app.options.authDomain ?? 'cocina-en-tu-casa.firebaseapp.com';
                actionCodeSettings = ActionCodeSettings(
                  url: 'https://$authDomain', // Use Firebase auth domain instead of localhost
                  handleCodeInApp: false,
                );
              }
              
              // Send email verification with Firebase auth domain (only if not already sent)
              if (!emailSent && actionCodeSettings != null) {
                await user.sendEmailVerification(actionCodeSettings);
                Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
              }
            } else {
              // For production web, use current origin - MUST be added to authorized domains
              if (baseUrl.isEmpty) {
                throw Exception('No se puede determinar la URL actual. Por favor asegúrate de que la aplicación esté ejecutándose en un dominio válido.');
              }
              actionCodeSettings = ActionCodeSettings(
                url: baseUrl, // Must be in authorized domains list
                handleCodeInApp: false,
              );
            }
          } else {
            // For mobile, try without actionCodeSettings first (Firebase default)
            // If that doesn't work, use Firebase auth domain
            // Note: For mobile apps, Firebase handles email links automatically
            bool emailSent = false;
            try {
              // Try sending without actionCodeSettings first (uses Firebase defaults)
              // This avoids authorization issues
              await user.sendEmailVerification();
              Logger.success('Verification email sent successfully (default settings) to ${user.email}', 'FirebaseAuthService');
              emailSent = true;
            } catch (defaultError) {
              // If default fails, try with actionCodeSettings
              Logger.warning('Default email send failed, trying with actionCodeSettings: $defaultError', 'FirebaseAuthService');
              final authDomain = _auth.app.options.authDomain ?? 'smart-recipe-fb.firebaseapp.com';
              actionCodeSettings = ActionCodeSettings(
                url: 'https://$authDomain', // Firebase auth domain should be authorized
                handleCodeInApp: true,
                androidPackageName: null, // Set if you have Android app package name
                iOSBundleId: null, // Set if you have iOS app bundle ID
              );
            }
            
            // Send email verification with custom settings (only if not already sent and actionCodeSettings was set)
            if (!emailSent && actionCodeSettings != null) {
              await user.sendEmailVerification(actionCodeSettings);
              Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
            }
          }
          
          // For web (non-localhost production), send email verification with custom settings
          if (kIsWeb && actionCodeSettings != null) {
            final baseUrl = Uri.base.origin;
            final isLocalhost = baseUrl.contains('localhost') || 
                               baseUrl.contains('127.0.0.1') || 
                               baseUrl.contains('0.0.0.0');
            
            // Only use actionCodeSettings if not localhost (localhost emails already sent above)
            if (!isLocalhost) {
              await user.sendEmailVerification(actionCodeSettings);
              Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
            }
          }
        } catch (e) {
          // Log the full error for debugging
          Logger.error('Failed to send verification email immediately', e, null, 'FirebaseAuthService');
          Logger.error('Error type: ${e.runtimeType}, Error message: ${e.toString()}', null, null, 'FirebaseAuthService');
          
          // Check if it's a FirebaseAuthException for better error handling
          if (e is FirebaseAuthException) {
            final errorCode = e.code;
            final errorMessage = e.message ?? e.toString();
            Logger.error('Firebase Auth Error Code: $errorCode, Message: $errorMessage', null, null, 'FirebaseAuthService');
            
            // Handle specific error codes
            if (errorCode == 'unauthorized-continue-uri' || errorCode == 'invalid-continue-uri') {
              // For mobile, try sending without actionCodeSettings as fallback
              if (!kIsWeb) {
                try {
                  Logger.info('Retrying email send without actionCodeSettings', 'FirebaseAuthService');
                  await user.sendEmailVerification(); // Send without actionCodeSettings
                  Logger.success('Verification email sent successfully (fallback method) to ${user.email}', 'FirebaseAuthService');
                  // Success with fallback - email sent, continue with registration
                } catch (fallbackError) {
                  Logger.error('Fallback email send also failed', fallbackError, null, 'FirebaseAuthService');
                  // Don't throw - allow registration to complete, user can resend email later
                  Logger.warning('Email verification will need to be sent manually later', 'FirebaseAuthService');
                }
              } else {
                // For web, log but don't block registration
                Logger.warning('URL de redirección no autorizada. Email verification may need to be sent manually.', 'FirebaseAuthService');
              }
            } else {
              // Log error but don't block registration - user can resend email
              Logger.warning('Email verification failed: ${_handleAuthException(e)}. User can resend from verification screen.', 'FirebaseAuthService');
            }
          } else {
            // Log error but don't block registration
            Logger.warning('Email verification failed: ${e.toString()}. User can resend from verification screen.', 'FirebaseAuthService');
          }
          // Don't throw - allow registration to complete successfully even if email fails
          // User can resend verification email from the verification screen
        }
      } else {
        Logger.warning('User or email is null, cannot send verification email', 'FirebaseAuthService');
        // Don't throw - allow registration to complete
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Log the Firebase error details before converting to user-friendly message
      Logger.error('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}', null, null, 'FirebaseAuthService');
      // Throw Exception with user-friendly message, preserving error code in the message
      throw Exception('${e.code}: ${_handleAuthException(e)}');
    } catch (e) {
      // Catch any other exceptions
      Logger.error('Unexpected error during registration', e, null, 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('El inicio de sesión con Google fue cancelado por el usuario');
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación de Google. Por favor intenta de nuevo.');
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Provide more user-friendly error messages
      final errorMessage = e.toString();
      if (errorMessage.contains('ClientID not set')) {
        throw Exception('El inicio de sesión con Google no está configurado correctamente. Por favor contacta al soporte.');
      } else if (errorMessage.contains('cancelled')) {
        throw Exception('El inicio de sesión con Google fue cancelado');
      } else {
        throw Exception('El inicio de sesión con Google falló. Por favor intenta de nuevo.');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Send password reset email
  /// 
  /// ⚠️ CRITICAL: Email templates MUST be configured in Firebase Console!
  /// 
  /// Quick Setup:
  /// 1. Firebase Console > Authentication > Templates > Password reset
  /// 2. Subject: "Restablece tu contraseña - Cocina en tu Casa"
  /// 3. Sender name: "Cocina en tu Casa"
  /// 4. Copy HTML from: docs/email_templates/password_reset_email.html
  /// 5. Paste and Save
  /// 
  /// See docs/EMAIL_SETUP_STEP_BY_STEP.md for detailed instructions.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      Logger.info('Sending password reset email to: $email', 'FirebaseAuthService');
      Logger.info('⚠️ IMPORTANT: If email not received, check Firebase Console > Authentication > Templates are configured!', 'FirebaseAuthService');
      
      // For web/localhost, send without actionCodeSettings first (Firebase defaults)
      // This avoids authorization issues and improves deliverability
      if (kIsWeb) {
        final baseUrl = Uri.base.origin;
        final isLocalhost = baseUrl.contains('localhost') || 
                           baseUrl.contains('127.0.0.1') || 
                           baseUrl.contains('0.0.0.0');
        
        if (isLocalhost) {
          // For localhost, send without actionCodeSettings (Firebase defaults)
          // This avoids authorization issues with localhost URLs
          try {
            Logger.info('Localhost detected, sending password reset email without actionCodeSettings', 'FirebaseAuthService');
            await _auth.sendPasswordResetEmail(email: email);
            Logger.success('Password reset email sent successfully (default settings) to $email', 'FirebaseAuthService');
            return;
          } catch (defaultError) {
            Logger.warning('Default email send failed for localhost, trying with Firebase auth domain: $defaultError', 'FirebaseAuthService');
            // Fallback: use Firebase auth domain instead of localhost
            final authDomain = _auth.app.options.authDomain ?? 'smart-recipe-fb.firebaseapp.com';
            await _auth.sendPasswordResetEmail(
              email: email,
              actionCodeSettings: ActionCodeSettings(
                url: 'https://$authDomain',
                handleCodeInApp: false,
              ),
            );
            Logger.success('Password reset email sent successfully to $email', 'FirebaseAuthService');
            return;
          }
        } else {
          // For production web, use current origin - MUST be added to authorized domains
          if (baseUrl.isEmpty) {
            throw Exception('Cannot determine current URL. Please ensure the app is running on a valid domain.');
          }
          await _auth.sendPasswordResetEmail(
            email: email,
            actionCodeSettings: ActionCodeSettings(
              url: baseUrl,
              handleCodeInApp: false,
            ),
          );
          Logger.success('Password reset email sent successfully to $email', 'FirebaseAuthService');
          return;
        }
      } else {
        // For mobile, send without actionCodeSettings first (Firebase defaults)
        // This avoids authorization issues and improves deliverability
        try {
          Logger.info('Sending password reset email without actionCodeSettings (mobile)', 'FirebaseAuthService');
          await _auth.sendPasswordResetEmail(email: email);
          Logger.success('Password reset email sent successfully (default settings) to $email', 'FirebaseAuthService');
        } catch (defaultError) {
          Logger.warning('Default email send failed, trying with Firebase auth domain: $defaultError', 'FirebaseAuthService');
          // Fallback: use Firebase auth domain
          final authDomain = _auth.app.options.authDomain ?? 'smart-recipe-fb.firebaseapp.com';
          await _auth.sendPasswordResetEmail(
            email: email,
            actionCodeSettings: ActionCodeSettings(
              url: 'https://$authDomain',
              handleCodeInApp: true,
            ),
          );
          Logger.success('Password reset email sent successfully to $email', 'FirebaseAuthService');
        }
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Failed to send password reset email', e, null, 'FirebaseAuthService');
      
      // Handle specific error codes with user-friendly messages
      String userMessage;
      switch (e.code) {
        case 'user-not-found':
          // Don't reveal that user doesn't exist (security best practice)
          userMessage = 'Si existe una cuenta con este correo, recibirás un enlace para restablecer tu contraseña. Por favor revisa tu bandeja de entrada y carpeta de spam.';
          Logger.info('User not found for password reset, but showing generic message for security', 'FirebaseAuthService');
          // Still return success to user (security best practice)
          return;
        case 'invalid-email':
          userMessage = 'El correo electrónico ingresado no es válido. Por favor verifica e intenta nuevamente.';
          break;
        case 'too-many-requests':
          userMessage = 'Demasiados intentos. Por favor espera unos minutos antes de intentar nuevamente.';
          break;
        case 'unauthorized-continue-uri':
        case 'invalid-continue-uri':
        // Try sending without actionCodeSettings as fallback
        try {
          Logger.info('Retrying password reset email send without actionCodeSettings (fallback)', 'FirebaseAuthService');
          await _auth.sendPasswordResetEmail(email: email);
          Logger.success('Password reset email sent successfully (fallback method) to $email', 'FirebaseAuthService');
            return;
        } catch (fallbackError) {
          Logger.error('Fallback password reset email send also failed', fallbackError, null, 'FirebaseAuthService');
          // Last resort: try with Firebase auth domain
          try {
            final authDomain = _auth.app.options.authDomain ?? 'smart-recipe-fb.firebaseapp.com';
            await _auth.sendPasswordResetEmail(
              email: email,
              actionCodeSettings: ActionCodeSettings(
                url: 'https://$authDomain',
                handleCodeInApp: !kIsWeb,
              ),
            );
            Logger.success('Password reset email sent successfully (using Firebase auth domain) to $email', 'FirebaseAuthService');
              return;
          } catch (finalError) {
            Logger.error('All password reset email send methods failed', finalError, null, 'FirebaseAuthService');
              userMessage = 'No se pudo enviar el correo de restablecimiento. Por favor verifica tu conexión e intenta nuevamente.';
              throw Exception(userMessage);
          }
        }
        default:
          userMessage = 'Error al enviar el correo de restablecimiento. Por favor intenta nuevamente más tarde.';
          break;
      }
      throw Exception(userMessage);
    } catch (e) {
      Logger.error('Failed to send password reset email', e, null, 'FirebaseAuthService');
      // If it's already a user-friendly Exception, rethrow it
      if (e is Exception && e.toString().contains('Por favor')) {
      rethrow;
      }
      // Otherwise, wrap in user-friendly message
      throw Exception('Error al enviar el correo de restablecimiento. Por favor verifica tu conexión e intenta nuevamente.');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay usuario conectado');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No hay usuario conectado');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay usuario conectado');
      }

      // Re-authenticate before deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No hay usuario conectado');
      }

      if (user.email == null) {
        throw Exception('El correo electrónico del usuario es nulo');
      }

      if (!user.emailVerified) {
        Logger.info('Sending verification email to: ${user.email}', 'FirebaseAuthService');
        
        // Send email verification with actionCodeSettings for email template customization
        // 
        // ⚠️ CRITICAL: Email templates MUST be configured in Firebase Console!
        // 
        // Quick Setup:
        // 1. Firebase Console > Authentication > Templates > Email address verification
        // 2. Subject: "Verifica tu correo electrónico - Cocina en tu Casa"
        // 3. Sender name: "Cocina en tu Casa"
        // 4. Copy HTML from: docs/email_templates/verification_email.html
        // 5. Paste and Save
        // 
        // See docs/EMAIL_SETUP_STEP_BY_STEP.md for detailed instructions.
        try {
          ActionCodeSettings? actionCodeSettings;
          
          // IMPORTANT: The URL must be in Firebase Console > Authentication > Settings > Authorized domains
          // For mobile apps, we use the Firebase auth domain which is always authorized
          // For web, we use the current origin (must be added to authorized domains)
          
          if (kIsWeb) {
            // For web, check if it's localhost - if so, try without actionCodeSettings first
            final baseUrl = Uri.base.origin;
            final isLocalhost = baseUrl.contains('localhost') || 
                               baseUrl.contains('127.0.0.1') || 
                               baseUrl.contains('0.0.0.0');
            
            if (isLocalhost) {
              // For localhost, try sending without actionCodeSettings first (Firebase defaults)
              // This avoids authorization issues with localhost URLs
              bool emailSent = false;
              try {
                Logger.info('Localhost detected, sending email without actionCodeSettings', 'FirebaseAuthService');
                await user.sendEmailVerification(); // Send without actionCodeSettings
                Logger.success('Verification email sent successfully (default settings) to ${user.email}', 'FirebaseAuthService');
                emailSent = true;
              } catch (defaultError) {
                Logger.warning('Default email send failed for localhost, trying with Firebase auth domain: $defaultError', 'FirebaseAuthService');
                // Fallback: use Firebase auth domain instead of localhost
                final authDomain = _auth.app.options.authDomain ?? 'cocina-en-tu-casa.firebaseapp.com';
                actionCodeSettings = ActionCodeSettings(
                  url: 'https://$authDomain', // Use Firebase auth domain instead of localhost
                  handleCodeInApp: false,
                );
              }
              
              // Send email verification with Firebase auth domain (only if not already sent)
              if (!emailSent && actionCodeSettings != null) {
                await user.sendEmailVerification(actionCodeSettings);
                Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
              }
            } else {
              // For production web, use current origin - MUST be added to authorized domains
              if (baseUrl.isEmpty) {
                throw Exception('No se puede determinar la URL actual. Por favor asegúrate de que la aplicación esté ejecutándose en un dominio válido.');
              }
              actionCodeSettings = ActionCodeSettings(
                url: baseUrl, // Must be in authorized domains list
                handleCodeInApp: false,
              );
            }
          } else {
            // For mobile, try without actionCodeSettings first (Firebase default)
            // If that doesn't work, use Firebase auth domain
            // Note: For mobile apps, Firebase handles email links automatically
            bool emailSent = false;
            try {
              // Try sending without actionCodeSettings first (uses Firebase defaults)
              // This avoids authorization issues
              await user.sendEmailVerification();
              Logger.success('Verification email sent successfully (default settings) to ${user.email}', 'FirebaseAuthService');
              emailSent = true;
            } catch (defaultError) {
              // If default fails, try with actionCodeSettings
              Logger.warning('Default email send failed, trying with actionCodeSettings: $defaultError', 'FirebaseAuthService');
              final authDomain = _auth.app.options.authDomain ?? 'smart-recipe-fb.firebaseapp.com';
              actionCodeSettings = ActionCodeSettings(
                url: 'https://$authDomain', // Firebase auth domain should be authorized
                handleCodeInApp: true,
                androidPackageName: null, // Set if you have Android app package name
                iOSBundleId: null, // Set if you have iOS app bundle ID
              );
            }
            
            // Send email verification with custom settings (only if not already sent and actionCodeSettings was set)
            if (!emailSent && actionCodeSettings != null) {
              await user.sendEmailVerification(actionCodeSettings);
              Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
            }
          }
          
          // For web (non-localhost production), send email verification with custom settings
          if (kIsWeb && actionCodeSettings != null) {
            final baseUrl = Uri.base.origin;
            final isLocalhost = baseUrl.contains('localhost') || 
                               baseUrl.contains('127.0.0.1') || 
                               baseUrl.contains('0.0.0.0');
            
            // Only use actionCodeSettings if not localhost (localhost emails already sent above)
            if (!isLocalhost) {
              await user.sendEmailVerification(actionCodeSettings);
              Logger.success('Verification email sent successfully to ${user.email}', 'FirebaseAuthService');
            }
          }
        } catch (e) {
          // Log the full error for debugging
          Logger.error('Failed to send verification email', e, null, 'FirebaseAuthService');
          Logger.error('Error type: ${e.runtimeType}, Error message: ${e.toString()}', null, null, 'FirebaseAuthService');
          
          // Check if it's a FirebaseAuthException for better error handling
          if (e is FirebaseAuthException) {
            final errorCode = e.code;
            final errorMessage = e.message ?? e.toString();
            Logger.error('Firebase Auth Error Code: $errorCode, Message: $errorMessage', null, null, 'FirebaseAuthService');
            
            // Handle specific error codes
            if (errorCode == 'unauthorized-continue-uri' || errorCode == 'invalid-continue-uri') {
              // Try sending without actionCodeSettings as fallback (works for both web and mobile)
              try {
                Logger.info('Retrying email send without actionCodeSettings (fallback)', 'FirebaseAuthService');
                await user.sendEmailVerification(); // Send without actionCodeSettings - uses Firebase defaults
                Logger.success('Verification email sent successfully (fallback method) to ${user.email}', 'FirebaseAuthService');
                // Success with fallback - email sent, no need to throw
              } catch (fallbackError) {
                Logger.error('Fallback email send also failed', fallbackError, null, 'FirebaseAuthService');
                // Last resort: try with Firebase auth domain
                try {
                  final authDomain = _auth.app.options.authDomain ?? 'cocina-en-tu-casa.firebaseapp.com';
                  await user.sendEmailVerification(
                    ActionCodeSettings(
                      url: 'https://$authDomain',
                      handleCodeInApp: !kIsWeb,
                    ),
                  );
                  Logger.success('Verification email sent successfully (using Firebase auth domain) to ${user.email}', 'FirebaseAuthService');
                } catch (finalError) {
                  Logger.error('All email send methods failed', finalError, null, 'FirebaseAuthService');
                  // Show user-friendly error message
                  throw Exception('No se pudo enviar el correo de verificación. Por favor intenta de nuevo más tarde o contacta al soporte.');
                }
              }
            } else {
              // Re-throw other errors
              throw Exception('Error al enviar el correo de verificación: ${_handleAuthException(e)}');
            }
          } else {
            // Re-throw with the original error message
            throw Exception('Error al enviar el correo de verificación: ${e.toString()}');
          }
        }
      } else {
        Logger.info('Email already verified, no need to send verification email', 'FirebaseAuthService');
      }
    } catch (e) {
      Logger.error('Email verification failed', e, null, 'FirebaseAuthService');
      throw Exception('Error al verificar el correo electrónico: $e');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reload user data
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil. Por favor usa una contraseña más fuerte.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con esta dirección de correo electrónico.';
      case 'invalid-email':
        return 'La dirección de correo electrónico no es válida.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Por favor contacta al soporte.';
      case 'user-not-found':
        return 'No se encontró una cuenta con esta dirección de correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Por favor intenta de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Por favor espera unos minutos e intenta de nuevo.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida. Por favor contacta al soporte.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Por favor verifica tu correo electrónico y contraseña.';
      case 'unauthorized-domain':
        return 'Este dominio de correo electrónico no está permitido. Por favor contacta al soporte o usa una dirección de correo diferente.';
      case 'invalid-continue-uri':
      case 'unauthorized-continue-uri':
        return 'URL de redirección no autorizada. Por favor contacta al soporte o verifica la configuración en Firebase Console.';
      default:
        // Check if error message contains domain-related keywords
        final message = e.message ?? '';
        if (message.toLowerCase().contains('domain') || 
            message.toLowerCase().contains('allowlist') ||
            message.toLowerCase().contains('not allowlisted')) {
          return 'Este dominio de correo electrónico no está permitido. Por favor contacta al soporte o usa una dirección de correo diferente.';
        }
        return message.isNotEmpty ? message : 'Ocurrió un error de autenticación.';
    }
  }
}

