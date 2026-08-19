/// Design System Zoe: ThemeData luxury.
///
/// Referências:
/// - ARCHITECTURE.md §Design System (Luxury Fashion): cores, tipografia, spacing
/// - ARCHITECTURE.md §Color Palette: ZoeColors
/// - ARCHITECTURE.md §Typography System: ZoeTypography
import 'package:flutter/material.dart';
import 'zoe_colors.dart';
import 'zoe_typography.dart';
import 'zoe_spacing.dart';

class ZoeTheme {
  /// Tema claro luxury (ARCHITECTURE.md §Design System)
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ZoeColors.primary,
      scaffoldBackgroundColor: ZoeColors.background,
      colorScheme: const ColorScheme.light(
        primary: ZoeColors.primary,
        onPrimary: ZoeColors.white,
        secondary: ZoeColors.secondary,
        onSecondary: ZoeColors.white,
        tertiary: ZoeColors.accent,
        surface: ZoeColors.surface,
        error: ZoeColors.error,
        onSurface: ZoeColors.secondary,
      ),

      // AppBar luxury
      appBarTheme: AppBarTheme(
        backgroundColor: ZoeColors.surface,
        foregroundColor: ZoeColors.secondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: ZoeTypography.headlineMedium,
      ),

      // Elevated button luxury
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZoeColors.primary,
          foregroundColor: ZoeColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ZoeSpacing.lg,
            vertical: ZoeSpacing.md,
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: ZoeTypography.labelLarge.copyWith(color: ZoeColors.white),
        ),
      ),

      // Input decoration luxury
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZoeColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
          borderSide: const BorderSide(color: ZoeColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ZoeSpacing.md,
          vertical: ZoeSpacing.sm,
        ),
        hintStyle: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
      ),

      // Card luxury
      cardTheme: CardThemeData(
        elevation: 0,
        color: ZoeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
        ),
      ),

      // Page transitions: easeInOutCubic (TECHNICAL_AUDIT §2.1)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: ZoeColors.lightGray,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
