import 'package:flutter/material.dart';

/// Shared theme tokens for the Soar Score Flutter apps.
///
/// Mirrors the baselines established by `soar_score_contest` (ticket 004)
/// and `soar_score_public` (ticket 005), which seed their themes from the
/// same colors and card radius. The apps keep their own theme files until a
/// later integration ticket moves them onto these tokens.
abstract final class SoarScoreThemeTokens {
  static const Color seedColor = Color(0xFF006399);
  static const Color primary = Color(0xFF006399);
  static const Color secondary = Color(0xFF2D6A4F);
  static const Color surface = Color(0xFFF8FAFC);
  // Custom high-viz accent for timers & max scores (from the contest app).
  static const Color highVizAmber = Color(0xFFD97706);

  static const double defaultBorderRadius = 12;
}
