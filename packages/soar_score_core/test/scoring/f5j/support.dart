import 'package:soar_score_core/soar_score_core.dart';

final f5j = F5jProfile();

/// Calculates a flight with the official defaults: working time 600 s, 1 point
/// per second, reference height 200 m, 0.5 and 3 points per meter.
F5jFlightResult flight(
  Map<String, Object?> components, {
  Map<String, Object?>? overrides,
  double landingBonus = 0,
}) =>
    f5j.calculate(components, overrides: overrides, landingBonus: landingBonus);

List<String> issueCodes(void Function() run) {
  try {
    run();
  } on ScoringValidationError catch (e) {
    return [for (final i in e.issues) i.code];
  }
  return const [];
}
