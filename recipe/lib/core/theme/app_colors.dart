import 'package:flutter/material.dart';

/// Application color palette
/// Brand: Cocina en tu Casa
/// Clean, modern, minimal – warm without clutter
class AppColors {
  // Primary Colors - Refined, contemporary
  static const Color primary = Color(0xFFE85D4C);
  static const Color primaryDark = Color(0xFFD14A3A);
  static const Color primaryLight = Color(0xFFFF7A6B);

  // Base Colors
  static const Color warmWhite = Color(0xFFFFFBF8);
  static const Color charcoal = Color(0xFF1A1A1A);

  // Secondary / Accents
  static const Color oliveGreen = Color(0xFF5B8C4A);
  static const Color cornYellow = Color(0xFFF5B942);
  static const Color softGray = Color(0xFFF0F0EF);

  // Legacy secondary (mapped to primary for compatibility)
  static const Color secondary = primary;
  static const Color secondaryDark = primaryDark;
  static const Color secondaryLight = primaryLight;

  // Neutral colors
  static const Color black = charcoal;
  static const Color white = Colors.white;
  static const Color background = warmWhite;
  static const Color surface = Colors.white;

  // Gray scale – clean, neutral
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F4);
  static const Color gray200 = Color(0xFFE8E8E6);
  static const Color gray300 = Color(0xFFD4D4D1);
  static const Color gray400 = Color(0xFFA8A8A5);
  static const Color gray500 = Color(0xFF73736F);
  static const Color gray600 = Color(0xFF52524E);
  static const Color gray700 = Color(0xFF3F3F3C);
  static const Color gray800 = Color(0xFF2D2D2B);
  static const Color gray900 = charcoal;

  // Status colors
  static const Color success = oliveGreen;
  static const Color error = Color(0xFFD94A4A);
  static const Color warning = cornYellow;
  static const Color info = primary;

  // Text colors
  static const Color textPrimary = charcoal;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Other
  static const Color divider = gray200;
  static const Color shadow = Color(0x0D000000);
}

