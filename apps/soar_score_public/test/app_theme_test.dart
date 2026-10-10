import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  group('PublicAppTheme', () {
    test('light theme is Material 3 with the seed-derived color scheme', () {
      final theme = PublicAppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      // Same seed as the contest app baseline (Deep Sky Blue).
      expect(theme.colorScheme.primary.toARGB32(), 0xFF006399);
    });

    test('dark theme is Material 3 with a dark color scheme', () {
      final theme = PublicAppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      // Dark scheme surfaces must actually be darker than light ones.
      expect(
        theme.colorScheme.surface.computeLuminance(),
        lessThan(PublicAppTheme.lightTheme.colorScheme.surface.computeLuminance()),
      );
    });
  });
}
