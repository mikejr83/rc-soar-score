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
