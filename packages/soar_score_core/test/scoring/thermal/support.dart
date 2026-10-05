import 'package:soar_score_core/soar_score_core.dart';

final thermal = ThermalProfile();

/// Calculates a flight with the official defaults: target 600 s, 1 point per
/// second, whole seconds.
ThermalFlightResult flight(
  Map<String, Object?> components, {
  Map<String, Object?>? overrides,
  double landingBonus = 0,
}) => thermal.calculate(
  components,
  overrides: overrides,
  landingBonus: landingBonus,
);

List<String> issueCodes(void Function() run) {
  try {
    run();
  } on ScoringValidationError catch (e) {
    return [for (final i in e.issues) i.code];
  }
  return const [];
}
