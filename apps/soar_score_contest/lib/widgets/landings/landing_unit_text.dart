import 'package:soar_score_core/soar_score_core.dart';

/// Wording for what a landing table's entry keys mean.
String landingUnitLabel(LandingInputUnit unit) => switch (unit) {
  LandingInputUnit.meters => 'Meters',
  LandingInputUnit.feet => 'Feet',
  LandingInputUnit.points => 'Points',
};
