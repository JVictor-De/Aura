/// Tema do portal do lojista.
import 'package:flutter/material.dart';

class PortalTheme {
  static const _primary = Color(0xFFC9A87C);
  static const _secondary = Color(0xFF2C2C2C);
  static const _background = Color(0xFFFAF9F7);
  static const _surface = Color(0xFFFFFFFF);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _primary,
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _secondary,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
