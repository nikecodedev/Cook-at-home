import 'package:flutter/material.dart';

/// Application color palette
/// Brand: Cocina en tu Casa
/// Personality: Warm, Helpful, Simple, Organized, Modern, Family-friendly
class AppColors {
  // Primary Colors - Brand Identity
  /// Tomato Red (#FA4F3E): Energía, comida, hogar
  static const Color primary = Color(0xFFFA4F3E);
  static const Color primaryDark = Color(0xFFE03D2C);
  static const Color primaryLight = Color(0xFFFF6B5A);

  // Base Colors
  /// Warm White (#FFF9F4): Cocina, luz suave
  static const Color warmWhite = Color(0xFFFFF9F4);
  /// Charcoal (#2D2D2D): Elegante, contraste
  static const Color charcoal = Color(0xFF2D2D2D);

  // Secondary Colors - Accents
  /// Olive Green (#7A8F2A): Frescura, vegetales
  static const Color oliveGreen = Color(0xFF7A8F2A);
  /// Corn Yellow (#FFCC66): Calidez, ingredientes
  static const Color cornYellow = Color(0xFFFFCC66);
  /// Soft Gray (#EDEDED): Neutro, limpio
  static const Color softGray = Color(0xFFEDEDED);

  // Legacy secondary (mapped to primary for compatibility)
  static const Color secondary = primary;
  static const Color secondaryDark = primaryDark;
  static const Color secondaryLight = primaryLight;

  // Neutral colors
  static const Color black = charcoal;
  static const Color white = Colors.white;
  static const Color background = warmWhite;
  static const Color surface = Colors.white;

  // Gray scale (updated to match brand)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = softGray;
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD0D0D0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = charcoal;

  // Status colors (warm, friendly tones)
  static const Color success = oliveGreen;
  static const Color error = Color(0xFFE63946); // Slightly softer red
  static const Color warning = cornYellow;
  static const Color info = primary;

  // Text colors
  static const Color textPrimary = charcoal;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Other
  static const Color divider = softGray;
  static const Color shadow = Color(0x1A000000); // Soft shadow for warm feel
}

