import 'package:flutter/material.dart';

/// Baseline Material 3 theme for the RC Soar Score Contest Management app.
///
/// Single source of truth for theming: `MaterialApp` in `app.dart` takes its
/// themes exclusively from this file (no inline `MaterialApp(theme:)` values).
abstract final class AppTheme {
    // Primary Seed Color: Deep Sky Blue
  static const Color _skyBlueSeed = Color(0xFF006399);
  static const Color _primaryColor = Color(0xFF006399);
  static const Color _secondaryColor = Color(0xFF2D6A4F);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  // Custom High-Viz Accent for Timers & Max Scores
  static const Color _highVizAmber = Color(0xFFD97706);

  static const double _defaultBorderRadius = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _skyBlueSeed,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _secondaryColor,
        tertiary: _highVizAmber,
        surface: _surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
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
        tertiary: _highVizAmber,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
    );
  }
}
