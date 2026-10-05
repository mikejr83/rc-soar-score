import '../../enums/discipline_type.dart';
import '../../enums/flight_outcome.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_field_definition.dart';
import '../profile/scoring_issue.dart';
import '../profile/scoring_profile.dart';
import 'f5j_flight_result.dart';
import 'f5j_height_penalty.dart';
import 'f5j_motor_restart_mode.dart';
import 'f5j_options.dart';
import 'f5j_zero_reason.dart';

/// The official F5J scoring profile, rules version 1.
///
/// Field keys and option keys follow
/// `plan/data-model/examples/disciplines/f5j.md`.
class F5jProfile extends ScoringProfile {
  F5jProfile();

  @override
  DisciplineType get discipline => DisciplineType.f5j;

  @override
  int get rulesVersion => 1;

  @override
  Map<String, Object?> get defaultOptions => const {
    'working_time': 900,
    'points_per_second': 1.0,
    'fractional_seconds': 0,
    'motor_restart_mode': 'allowed',
    'reference_launch_height': 200,
    'minor_penalty_per_meter': 0.5,
    'major_penalty_per_meter': 3.0,
    'group_score_mode': 'Normalized',
    'rounding_mode': 'Round',
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
      dependsOn: ['launch_height'],
    ),
    ScoringFieldDefinition(
      id: 'launch_height',
      label: 'Launch Height',
      type: ScoreFieldType.int,
      unit: 'm',
      min: 1,
      dependsOn: ['time_flown', 'no_altitude_recorded'],
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
    ),
    ScoringFieldDefinition(
      id: 'motor_restart',
      label: 'Motor Restart',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['no_altitude_recorded'],
    ),
    ScoringFieldDefinition(
      id: 'out_of_bounds',
      label: 'Out of Bounds',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['no_altitude_recorded'],
    ),
    ScoringFieldDefinition(
      id: 'no_altitude_recorded',
      label: 'No Altitude Recorded',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
      dependsOn: ['motor_restart', 'out_of_bounds', 'late_landing'],
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

  /// A motor restart together with out of bounds is allowed and records both
  /// reasons. No altitude recorded excludes every other status.
  @override
  List<ScoringIssue> validateCombination(Map<String, Object?> components) {
    final noAltitude = _flag(components, 'no_altitude_recorded');
    final issues = <ScoringIssue>[];
    if (noAltitude &&
        (_flag(components, 'motor_restart') ||
            _flag(components, 'out_of_bounds') ||
            _flag(components, 'late_landing'))) {
      issues.add(
        const ScoringIssue(
          code: 'exclusive_status',
          fieldId: 'no_altitude_recorded',
          message:
              'No altitude recorded cannot be combined with a motor restart, '
              'out of bounds, or a late landing.',
        ),
      );
    }
    final forcedZero =
        noAltitude ||
        _flag(components, 'motor_restart') ||
        _flag(components, 'out_of_bounds');
    if (!forcedZero) {
      final hasTime = components['time_flown'] != null;
      final hasHeight = components['launch_height'] != null;
      if (hasTime && !hasHeight) {
        issues.add(
          const ScoringIssue(
            code: 'required',
            fieldId: 'launch_height',
            message:
                'Launch height is required unless no altitude was recorded.',
          ),
        );
      } else if (hasHeight && !hasTime) {
        issues.add(
          const ScoringIssue(
            code: 'required',
            fieldId: 'time_flown',
            message: 'Time flown is required with a launch height.',
          ),
        );
      }
    }
    return issues;
  }

  /// Calculates one flight.
  ///
  /// [overrides] are the contest's option overrides over the official
  /// defaults. [landingBonus] is the point value of the landing table entry
  /// the pilot selected, which the caller resolves from the stored table.
  ///
  /// A motor restart, out of bounds, or no altitude recorded is a forced
  /// zero: time, height and landing are ignored and the reasons are kept.
  /// A blank score is an ordinary zero with no reason. Anything invalid
  /// throws [ScoringValidationError] and nothing is repaired.
  F5jFlightResult calculate(
    Map<String, Object?> components, {
    Map<String, Object?>? overrides,
    double landingBonus = 0,
  }) {
    if (!landingBonus.isFinite || landingBonus < 0) {
      throw ArgumentError.value(landingBonus, 'landingBonus');
    }
    final options = this.options(overrides);
    validateOrThrow(components);

    final restart = _flag(components, 'motor_restart');
    if (restart && options.motorRestartMode == F5jMotorRestartMode.notAllowed) {
      throw ScoringValidationError([
        const ScoringIssue(
          code: 'not_allowed',
          fieldId: 'motor_restart',
          message: 'Motor restart is not part of this contest\'s entry.',
        ),
      ]);
    }

    final reasons = [
      if (restart) F5jZeroReason.motorRestart,
      if (_flag(components, 'out_of_bounds')) F5jZeroReason.outOfBounds,
      if (_flag(components, 'no_altitude_recorded'))
        F5jZeroReason.noAltitudeRecorded,
    ];
    final flightPenalty = (components['flight_penalty'] as int? ?? 0)
        .toDouble();

    if (reasons.isNotEmpty) {
      return F5jFlightResult(
        outcome: FlightOutcome.zero,
        zeroReasons: reasons,
        flightPenalty: flightPenalty,
        motorRestartMode: options.motorRestartMode,
        nonDroppable:
            restart &&
            options.motorRestartMode == F5jMotorRestartMode.nonDroppable,
      );
    }
    final time = components['time_flown'] as num?;
    final height = components['launch_height'] as int?;
    if (time == null || height == null) {
      return F5jFlightResult(
        outcome: FlightOutcome.zero,
        flightPenalty: flightPenalty,
        motorRestartMode: options.motorRestartMode,
      );
    }

    final late = _flag(components, 'late_landing');
    return F5jFlightResult(
      outcome: FlightOutcome.scored,
      lateLanding: late,
      flightPoints: options.duration.flightPoints(time.toDouble()),
      landingBonus: late ? 0 : landingBonus,
      heightPenalty: f5jHeightPenalty(
        altitude: height,
        referenceHeight: options.referenceLaunchHeight,
        minorPerMeter: options.minorPenaltyPerMeter,
        majorPerMeter: options.majorPenaltyPerMeter,
      ),
      flightPenalty: flightPenalty,
      motorRestartMode: options.motorRestartMode,
    );
  }

  /// The parsed options of a contest's [overrides] over the defaults.
  F5jOptions options([Map<String, Object?>? overrides]) =>
      F5jOptions.fromMap(resolveOptions(overrides));
}
