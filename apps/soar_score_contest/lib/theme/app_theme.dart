import 'package:flutter/material.dart';

/// Baseline Material 3 theme for the RC Soar Score Contest Management app.
///
/// Single source of truth for theming: `MaterialApp` in `app.dart` takes its
/// themes exclusively from this file (no inline `MaterialApp(theme:)` values).
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF1E88E5);

  static ThemeData light() {
    return _build(Brightness.light);
  }

  static ThemeData dark() {
    return _build(Brightness.dark);
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }
}
