import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme is Material 3 with the seed-derived color scheme', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, isA<Color>());
    });

    test('dark theme is Material 3 with a dark color scheme', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      // Dark scheme surfaces must actually be darker than light ones.
      expect(
        theme.colorScheme.surface.computeLuminance(),
        lessThan(AppTheme.lightTheme.colorScheme.surface.computeLuminance()),
      );
    });
  });
}
