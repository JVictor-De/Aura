/// Paleta de cores luxury do Zoe.
///
/// Referência direta: ARCHITECTURE.md §Color Palette
import 'package:flutter/material.dart';

abstract class ZoeColors {
  // PRIMARY - Champagne Rose
  static const Color primary = Color(0xFFC9A87C);
  static const Color primaryLight = Color(0xFFE5D4B8);
  static const Color primaryDark = Color(0xFF9E7B4F);
  static const Color primaryHover = Color(0xFFB8956A);
  static const Color primaryPressed = Color(0xFFA88358);

  // SECONDARY - Deep Charcoal
  static const Color secondary = Color(0xFF2C2C2C);
  static const Color secondaryLight = Color(0xFF4A4A4A);
  static const Color secondaryDark = Color(0xFF1A1A1A);

  // ACCENT - Rose Gold
  static const Color accent = Color(0xFFB76E79);
  static const Color accentLight = Color(0xFFD4A5AC);
  static const Color accentDark = Color(0xFF8B4D55);

  // NEUTRALS
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAF9F7);
  static const Color cream = Color(0xFFF5F3EF);
  static const Color lightGray = Color(0xFFE8E6E3);
  static const Color mediumGray = Color(0xFFB0ADA8);
  static const Color darkGray = Color(0xFF6B6966);
  static const Color charcoal = Color(0xFF3D3D3D);
  static const Color black = Color(0xFF1A1A1A);

  // SEMANTIC
  static const Color success = Color(0xFF4A7C59);
  static const Color successLight = Color(0xFFD4E5D8);
  static const Color warning = Color(0xFFD4A574);
  static const Color warningLight = Color(0xFFFAECDD);
  static const Color error = Color(0xFFC45B5B);
  static const Color errorLight = Color(0xFFF5D5D5);
  static const Color info = Color(0xFF5B7EC4);
  static const Color infoLight = Color(0xFFD5DEF5);

  // SURFACE
  static const Color background = Color(0xFFFAF9F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F3EF);
  static const Color overlay = Color(0x801A1A1A);

  // TEXT
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6966);
  static const Color textDisabled = Color(0xFFB0ADA8);

  // DIVIDER
  static const Color divider = Color(0xFFE8E6E3);
}
