import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

/// Colour roles the matrix page needs beyond the Material 3 scheme: a warning
/// text colour, a success container, and the team palette. Each has a light
/// and a dark value, and every use pairs the colour with text or an icon.
class MatrixColors {
  const MatrixColors._(this.brightness);

  factory MatrixColors.of(BuildContext context) =>
      MatrixColors._(Theme.of(context).brightness);

  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;

  /// Warning text and outlines on a surface. The amber accent is below 4.5:1
  /// as text on light surfaces, so warnings use this darker amber.
  Color get warn => AppStatusColors.getWarning(_dark);
  Color get success => AppStatusColors.getSuccess(_dark);
  Color get successContainer => AppStatusColors.getSuccessContainer(_dark);
  Color get onSuccessContainer => AppStatusColors.getOnSuccessContainer(_dark);

  static const _light = [
    (Color(0xFFCDE5FF), Color(0xFF001D32)),
    (Color(0xFFB1F1CE), Color(0xFF002113)),
    (Color(0xFFFFDDB8), Color(0xFF2C1600)),
    (Color(0xFFFFD8E4), Color(0xFF3E001D)),
    (Color(0xFFE9DDFF), Color(0xFF22005D)),
    (Color(0xFFB8F0F0), Color(0xFF002020)),
    (Color(0xFFFFDAD6), Color(0xFF410002)),
    (Color(0xFFDDE7A6), Color(0xFF1A1E00)),
    (Color(0xFFFFD9C2), Color(0xFF331200)),
    (Color(0xFFC9D7F8), Color(0xFF0E1C3A)),
    (Color(0xFFF3D3F8), Color(0xFF36003F)),
    (Color(0xFFDCE1E6), Color(0xFF191C1E)),
  ];

  static const _darkPalette = [
    (Color(0xFF00497A), Color(0xFFCDE5FF)),
    (Color(0xFF005236), Color(0xFFB1F1CE)),
    (Color(0xFF653E00), Color(0xFFFFDDB8)),
    (Color(0xFF7B2949), Color(0xFFFFD8E4)),
    (Color(0xFF4F378A), Color(0xFFE9DDFF)),
    (Color(0xFF004F50), Color(0xFFB8F0F0)),
    (Color(0xFF93000A), Color(0xFFFFDAD6)),
    (Color(0xFF434B00), Color(0xFFDDE7A6)),
    (Color(0xFF723600), Color(0xFFFFD9C2)),
    (Color(0xFF2A4678), Color(0xFFD7E3FF)),
    (Color(0xFF5E2D68), Color(0xFFF3D3F8)),
    (Color(0xFF44474C), Color(0xFFE0E3E8)),
  ];

  /// The container and on-container colours of team slot [index].
  (Color, Color) team(int index) {
    final palette = _dark ? _darkPalette : _light;
    return palette[index % palette.length];
  }
}
