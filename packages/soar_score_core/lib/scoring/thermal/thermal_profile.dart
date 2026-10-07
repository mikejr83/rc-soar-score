import '../../enums/discipline_type.dart';
import '../../enums/flight_outcome.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_field_definition.dart';
import '../profile/scoring_issue.dart';
import '../profile/scoring_profile.dart';
import 'thermal_flight_result.dart';
import 'thermal_options.dart';
import 'thermal_zero_reason.dart';

/// The official Thermal Duration scoring profile, rules version 1.
///
/// Field keys and option keys follow
/// `plan/data-model/examples/disciplines/thermal.md`.
class ThermalProfile extends ScoringProfile {
  ThermalProfile();

  @override
  DisciplineType get discipline => DisciplineType.thermalDuration;

  @override
  int get rulesVersion => 1;

  /// The official defaults. Thermal rounds the group score to whole points
  /// (0 decimal places).
  @override
  Map<String, Object?> get defaultOptions => const {
    'target_time': 600,
    'points_per_second': 1.0,
    'fractional_seconds': 0,
    'group_score_mode': 'Normalized',
    'rounding_mode': 'Round',
    'decimal_places': 0,
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
      dependsOn: ['overflight_gt_one_min'],
    ),
    ScoringFieldDefinition(
      id: 'landing',
      label: 'Landing',
      type: ScoreFieldType.landing,
    ),
    ScoringFieldDefinition(
      id: 'out_of_bounds',
      label: 'Out of Bounds',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['overflight_gt_one_min'],
    ),
    ScoringFieldDefinition(
      id: 'overflight_gt_one_min',
      label: 'Overflight > 1 Min',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['time_flown', 'out_of_bounds'],
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

  static bool _flag(Map<String, Object?> components, String id) =>
      components[id] == true;

  /// Out of bounds and an over-flight of more than a minute are mutually
  /// exclusive, and the over-flight flag needs a time flown.
  @override
  List<ScoringIssue> validateCombination(Map<String, Object?> components) {
    final issues = <ScoringIssue>[];
    final outOfBounds = _flag(components, 'out_of_bounds');
    final overflight = _flag(components, 'overflight_gt_one_min');
    if (outOfBounds && overflight) {
      issues.add(
        const ScoringIssue(
          code: 'exclusive_status',
          message: 'Select only one of out of bounds or overflight > 1 min.',
        ),
      );
    }
    if (overflight && components['time_flown'] == null) {
      issues.add(
        const ScoringIssue(
          code: 'required',
          fieldId: 'time_flown',
          message: 'Time flown is required with an overflight > 1 min.',
        ),
      );
    }
    return issues;
  }

  /// Calculates one flight.
  ///
  /// [overrides] are the contest's option overrides over the official
  /// defaults. [landingBonus] is the point value of the landing table entry
  /// the pilot selected, which the caller resolves from the stored table.
  ///
  /// Out of bounds or an over-flight of more than a minute is a forced zero:
  /// time and landing are ignored and the reason is kept. A blank score is an
  /// ordinary zero with no reason. The over-flight flag must be set exactly
  /// when the time is more than a minute past the target. Anything invalid
  /// throws [ScoringValidationError] and nothing is repaired.
  ThermalFlightResult calculate(
    Map<String, Object?> components, {
    Map<String, Object?>? overrides,
    double landingBonus = 0,
  }) {
    if (!landingBonus.isFinite || landingBonus < 0) {
      throw ArgumentError.value(landingBonus, 'landingBonus');
    }
    final options = this.options(overrides);
    validateOrThrow(components);

    final rules = options.targetTime;
    final time = (components['time_flown'] as num?)?.toDouble();
    final outOfBounds = _flag(components, 'out_of_bounds');
    final overflight = _flag(components, 'overflight_gt_one_min');

    if (time != null && !outOfBounds) {
      final over = rules.isOverflightOverLimit(time);
      if (over != overflight) {
        throw ScoringValidationError([
          ScoringIssue(
            code: over ? 'required' : 'not_allowed',
            fieldId: 'overflight_gt_one_min',
            message: over
                ? 'Time flown is more than a minute past the target; mark '
                      'overflight > 1 min.'
                : 'Overflight > 1 min needs a time more than a minute past '
                      'the target.',
          ),
        ]);
      }
    }

    final flightPenalty = (components['flight_penalty'] as int? ?? 0)
        .toDouble();

    final reasons = [
      if (outOfBounds) ThermalZeroReason.outOfBounds,
      if (overflight) ThermalZeroReason.overflightOverOneMinute,
    ];
    if (reasons.isNotEmpty) {
      return ThermalFlightResult(
        outcome: FlightOutcome.zero,
        zeroReasons: reasons,
        flightPenalty: flightPenalty,
      );
    }
    if (time == null) {
      return ThermalFlightResult(
        outcome: FlightOutcome.zero,
        flightPenalty: flightPenalty,
      );
    }

    return ThermalFlightResult(
      outcome: FlightOutcome.scored,
      flightPoints: rules.flightPoints(time),
      landingBonus: landingBonus,
      overflightSeconds: rules.overflightSeconds(time),
      flightPenalty: flightPenalty,
    );
  }

  /// The parsed options of a contest's [overrides] over the defaults.
  ThermalOptions options([Map<String, Object?>? overrides]) =>
      ThermalOptions.fromMap(resolveOptions(overrides));
}
