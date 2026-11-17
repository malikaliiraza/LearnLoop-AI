import 'package:flutter/material.dart';

/// Design tokens for LearnLoop AI.
///
/// Deep indigo + violet: studying at night, focused. Amber is used only for
/// "needs review" and the tutor's re-explanation callout.
class AppTheme {
  AppTheme._();

  static const Color primaryIndigo = Color(0xFF1E1B4B);
  static const Color primaryViolet = Color(0xFF6D28D9);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color backgroundLavender = Color(0xFFF5F3FF);
  static const Color reviewAmber = Color(0xFFD97706);
  static const Color correctGreen = Color(0xFF15803D);
  static const Color wrongRed = Color(0xFFB91C1C);

  static const double radius = 16;
  static const double spacing = 16;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryViolet,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLavender,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
