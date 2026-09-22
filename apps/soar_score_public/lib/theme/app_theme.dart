import 'package:flutter/material.dart';

/// Baseline Material 3 theme for the RC Soar Score public site.
///
/// Single source of truth for theming: `MaterialApp` in `app.dart` takes its
/// themes exclusively from this file (no inline `MaterialApp(theme:)` values).
///
/// The public site keeps its own theme file independent from the contest
/// app, but starts from the same seed color so the two apps feel related.
abstract final class AppTheme {
  // Primary Seed Color: Deep Sky Blue
  static const Color _skyBlueSeed = Color(0xFF006399);
  static const Color _primaryColor = Color(0xFF006399);
  static const Color _secondaryColor = Color(0xFF2D6A4F);
  static const Color _surfaceColor = Color(0xFFF8FAFC);

  static const double _defaultBorderRadius = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _skyBlueSeed,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _secondaryColor,
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
