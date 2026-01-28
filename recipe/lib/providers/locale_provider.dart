import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../core/localization/app_localizations.dart';
import '../services/firestore/firestore_service.dart';
import 'profile_provider.dart';

/// Provider for current app locale
/// Priority: User preference > Device locale > Default (Spanish)
final appLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return LocaleNotifier(firestoreService, ref);
});

/// Notifier for managing app locale
class LocaleNotifier extends StateNotifier<Locale> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  LocaleNotifier(this._firestoreService, this._ref) : super(_getDefaultLocale()) {
    _initializeLocale();
    _watchProfileChanges();
  }

  /// Initialize locale from user preference or device
  Future<void> _initializeLocale() async {
    try {
      // Get device locale
      final deviceLocale = _getDeviceLocale();
      
      // Try to get user preference
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        try {
          final profile = await _firestoreService.getUserProfile(userId);
          if (profile != null && profile.languagePreference != null) {
            final preferredLocale = _parseLocale(profile.languagePreference!);
            if (preferredLocale != null) {
              state = preferredLocale;
              return;
            }
          }
        } catch (e) {
          // Fall back to device locale if profile fetch fails
        }
      }
      
      // Use device locale if no user preference
      state = deviceLocale;
    } catch (e) {
      // Fall back to default
      state = _getDefaultLocale();
    }
  }

  /// Watch profile stream for language preference changes
  void _watchProfileChanges() {
    _ref.listen(profileStreamProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null && profile.languagePreference != null) {
          final preferredLocale = _parseLocale(profile.languagePreference!);
          if (preferredLocale != null && state != preferredLocale) {
            state = preferredLocale;
          }
        } else if (profile != null && profile.languagePreference == null) {
          // User cleared preference, use device locale
          final deviceLocale = _getDeviceLocale();
          if (state != deviceLocale) {
            state = deviceLocale;
          }
        }
      });
    });
  }

  /// Set locale preference for current user
  Future<void> setLocalePreference(String languageCode) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      // Update locale immediately
      final locale = _parseLocale(languageCode) ?? _getDefaultLocale();
      state = locale;

      // Save to user profile
      await _firestoreService.updateUserProfile(
        userId: userId,
        languagePreference: languageCode,
      );
      
      // Invalidate profile stream to trigger refresh
      _ref.invalidate(profileStreamProvider);
    } catch (e) {
      // Log error but keep current locale
    }
  }

  /// Get device locale
  Locale _getDeviceLocale() {
    final deviceLocales = ui.PlatformDispatcher.instance.locales;
    if (deviceLocales.isNotEmpty) {
      final deviceLocale = deviceLocales.first;
      // Check if device locale is supported
      if (AppLocalizations.supportedLocales.any(
        (locale) => locale.languageCode == deviceLocale.languageCode,
      )) {
        // Return matching supported locale
        return AppLocalizations.supportedLocales.firstWhere(
          (locale) => locale.languageCode == deviceLocale.languageCode,
        );
      }
    }
    return _getDefaultLocale();
  }

  /// Parse language code to Locale
  Locale? _parseLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return const Locale('en', 'US');
      case 'es':
        return const Locale('es', 'ES');
      default:
        return null;
    }
  }

  /// Get default locale (Spanish)
  static Locale _getDefaultLocale() {
    return const Locale('es', 'ES');
  }
}
