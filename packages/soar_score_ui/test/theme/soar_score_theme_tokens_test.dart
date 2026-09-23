import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  group('SoarScoreThemeTokens', () {
    test('matches the contest and public app baselines', () {
      // Same seed used by both app theme baselines (tickets 004 and 005).
      expect(SoarScoreThemeTokens.seedColor, const Color(0xFF006399));
      expect(SoarScoreThemeTokens.primary, const Color(0xFF006399));
      // Secondary from the contest app baseline.
      expect(SoarScoreThemeTokens.secondary, const Color(0xFF2D6A4F));
      expect(SoarScoreThemeTokens.surface, const Color(0xFFF8FAFC));
      // High-viz accent from the contest app baseline.
      expect(SoarScoreThemeTokens.highVizAmber, const Color(0xFFD97706));
      // Card radius from both app baselines.
      expect(SoarScoreThemeTokens.defaultBorderRadius, 12);
    });
  });
}
