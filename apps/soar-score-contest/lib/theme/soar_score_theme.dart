import 'package:flutter/material.dart';

class SoarScoreTheme {
  // Primary Seed Color: Deep Sky Blue
  static const Color _skyBlueSeed = Color(0xFF006399);

  // Custom High-Viz Accent for Timers & Max Scores
  static const Color highVizAmber = Color(0xFFD97706);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _skyBlueSeed,
        brightness: Brightness.light,
        primary: const Color(0xFF006399),
        secondary: const Color(0xFF2D6A4F),
        tertiary: highVizAmber,
        surface: const Color(0xFFF8FAFC),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _skyBlueSeed,
        brightness: Brightness.dark,
        tertiary: const Color(0xFFF59E0B),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
