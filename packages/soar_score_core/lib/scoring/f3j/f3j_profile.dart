import '../../enums/discipline_type.dart';
import '../../enums/flight_outcome.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../profile/scoring_field_definition.dart';
import '../profile/scoring_profile.dart';
import 'f3j_flight_result.dart';
import 'f3j_options.dart';
import 'f3j_zero_reason.dart';

/// The official F3J scoring profile, rules version 1.
///
/// Field keys and option keys follow
/// `plan/data-model/examples/disciplines/f3j.md`.
class F3jProfile extends ScoringProfile {
  F3jProfile();

  /// The fixed late landing penalty. It is a rule, not a contest option.
  static const latePenaltyPoints = 30.0;

  @override
  DisciplineType get discipline => DisciplineType.f3j;

  @override
  int get rulesVersion => 1;

  @override
  Map<String, Object?> get defaultOptions => const {
    'working_time': 600,
    'points_per_second': 1.0,
    'fractional_seconds': 1,
    'group_score_mode': 'Normalized',
    'rounding_mode': 'Truncate',
    'decimal_places': 1,
  };

  @override
  final List<ScoringFieldDefinition> fields = List.unmodifiable([
    ScoringFieldDefinition(
      id: 'time_flown',
      label: 'Time Flown',
      type: ScoreFieldType.time,
      unit: 's',
      precision: 3,
      min: 0,
    ),
    ScoringFieldDefinition(
      id: 'landing',
      label: 'Landing',
      type: ScoreFieldType.landing,
      dependsOn: ['late_landing'],
    ),
    ScoringFieldDefinition(
      id: 'late_landing',
      label: 'Late Landing',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['out_of_bounds'],
    ),
    ScoringFieldDefinition(
      id: 'out_of_bounds',
      label: 'Out of Bounds',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'flight_penalty',
      label: 'Flight Penalty',
      type: ScoreFieldType.int,
      min: 0,
    ),
    ScoringFieldDefinition(
      id: 'raw_score',
      label: 'Raw Score',
      type: ScoreFieldType.float,
      kind: ScoreFieldKind.derived,
    ),
  ]);

  /// Calculates one flight.
  ///
  /// [overrides] are the contest's option overrides over the official
  /// defaults. [landingBonus] is the point value of the landing table entry
  /// the pilot selected, which the caller resolves from the stored table.
  ///
  /// Out of bounds is a forced zero: time, landing and a late landing flag
  /// are ignored. A late landing keeps the flight points, loses the landing
  /// bonus and takes the fixed 30 point penalty. A blank score is an ordinary
  /// zero with no reason. Anything invalid throws `ScoringValidationError`
  /// and nothing is repaired.
  F3jFlightResult calculate(
    Map<String, Object?> components, {
    Map<String, Object?>? overrides,
    double landingBonus = 0,
  }) {
    if (!landingBonus.isFinite || landingBonus < 0) {
      throw ArgumentError.value(landingBonus, 'landingBonus');
    }
    final options = this.options(overrides);
    validateOrThrow(components);

    final flightPenalty = (components['flight_penalty'] as int? ?? 0)
        .toDouble();

    if (components['out_of_bounds'] == true) {
      return F3jFlightResult(
        outcome: FlightOutcome.zero,
        zeroReasons: const [F3jZeroReason.outOfBounds],
        flightPenalty: flightPenalty,
      );
    }
    final time = components['time_flown'] as num?;
    if (time == null) {
      return F3jFlightResult(
        outcome: FlightOutcome.zero,
        flightPenalty: flightPenalty,
      );
    }

    final late = components['late_landing'] == true;
    return F3jFlightResult(
      outcome: FlightOutcome.scored,
      lateLanding: late,
      flightPoints: options.duration.flightPoints(time.toDouble()),
      landingBonus: late ? 0 : landingBonus,
      latePenalty: late ? latePenaltyPoints : 0,
      flightPenalty: flightPenalty,
    );
  }

  /// The parsed options of a contest's [overrides] over the defaults.
  F3jOptions options([Map<String, Object?>? overrides]) =>
      F3jOptions.fromMap(resolveOptions(overrides));
}
