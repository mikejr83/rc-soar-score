import 'package:soar_score_core/soar_score_core.dart';

/// The raw score of typed values, worked out here so the director sees it
/// before saving. The server is the authority: a saved value replaces this.
///
/// Returns null when the values do not make a valid flight yet.
double? previewRawScore(
  Map<String, Object?> components, {
  required Map<String, Object?> discipline,
  required List<LandingResult> landings,
}) {
  try {
    var bonus = 0.0;
    final key = components['landing'];
    if (key != null) {
      for (final landing in landings) {
        if (landing.entryKey == key) bonus = landing.pointValue.toDouble();
      }
    }
    final flight = F5jProfile().calculate(
      components,
      overrides: discipline,
      landingBonus: bonus,
    );
    return flight.rawScore;
  } on Object {
    return null;
  }
}

/// The height penalty of a launch of [height] metres under the contest's
/// options, or null when it cannot be worked out.
double? previewHeightPenalty(
  int height, {
  required Map<String, Object?> discipline,
}) {
  try {
    return F5jProfile().calculate({
      'time_flown': 1,
      'launch_height': height,
    }, overrides: discipline).heightPenalty;
  } on Object {
    return null;
  }
}
