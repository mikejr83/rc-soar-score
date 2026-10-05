import '../../enums/discipline_type.dart';
import '../../enums/flight_outcome.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_field_definition.dart';
import '../profile/scoring_issue.dart';
import '../profile/scoring_profile.dart';
import 'ales_flight_result.dart';
import 'ales_options.dart';
import 'ales_zero_reason.dart';

/// The official ALES scoring profile, rules version 1.
///
/// Field keys and option keys follow
/// `plan/data-model/examples/disciplines/ales.md`.
class AlesProfile extends ScoringProfile {
  AlesProfile();

  @override
  DisciplineType get discipline => DisciplineType.ales;

  @override
  int get rulesVersion => 1;

  /// The platform rounding default (1 decimal) applies: the ALES rules do not
  /// give one.
  @override
  Map<String, Object?> get defaultOptions => const {
    'target_time': 600,
    'points_per_second': 1.0,
    'fractional_seconds': 0,
    'group_score_mode': 'Time',
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
    ),
    ScoringFieldDefinition(
      id: 'landing',
      label: 'Landing',
      type: ScoreFieldType.landing,
    ),
    ScoringFieldDefinition(
      id: 'motor_restart',
      label: 'Motor Restart',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'out_of_bounds',
      label: 'Out of Bounds',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'overflight_gt_one_min',
      label: 'Over-Flight of Greater Than One Minute',
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

  static const _zeroStatusIds = [
    'motor_restart',
    'out_of_bounds',
    'overflight_gt_one_min',
  ];

  /// Motor restart, out of bounds and over-flight are mutually exclusive;
  /// each one alone forces a zero.
  @override
  List<ScoringIssue> validateCombination(Map<String, Object?> components) {
    final selected = _zeroStatusIds.where((id) => components[id] == true);
    if (selected.length <= 1) return const [];
    return const [
      ScoringIssue(
        code: 'exclusive_status',
        message:
            'Select only one of motor restart, out of bounds, or over-flight '
            'of more than one minute.',
      ),
    ];
  }

  static bool _flag(Map<String, Object?> components, String id) =>
      components[id] == true;

  /// Calculates one flight.
  ///
  /// [overrides] are the contest's option overrides over the official
  /// defaults. [landingBonus] is the point value of the landing table entry
  /// the pilot selected, which the caller resolves from the stored table.
  ///
  /// A motor restart, out of bounds, or an over-flight of more than a minute
  /// is a forced zero: time and landing are ignored and the reason is kept. A
  /// blank score is an ordinary zero with no reason. Without a motor restart
  /// or out of bounds, the over-flight flag must be set exactly when the time
  /// is more than a minute past the target; the application never derives it.
  /// Anything invalid throws [ScoringValidationError] and nothing is
  /// repaired.
  AlesFlightResult calculate(
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
    final restart = _flag(components, 'motor_restart');
    final outOfBounds = _flag(components, 'out_of_bounds');
    final overflight = _flag(components, 'overflight_gt_one_min');

    if (time != null && !restart && !outOfBounds) {
      final over = rules.isOverflightOverLimit(time);
      if (over != overflight) {
        throw ScoringValidationError([
          ScoringIssue(
            code: over ? 'required' : 'not_allowed',
            fieldId: 'overflight_gt_one_min',
            message: over
                ? 'Time flown is more than a minute past the target; mark '
                      'over-flight of more than one minute.'
                : 'Over-flight of more than one minute needs a time more than '
                      'a minute past the target.',
          ),
        ]);
      }
    }

    final flightPenalty = (components['flight_penalty'] as int? ?? 0)
        .toDouble();

    final reasons = [
      if (restart) AlesZeroReason.motorRestart,
      if (outOfBounds) AlesZeroReason.outOfBounds,
      if (overflight) AlesZeroReason.overflightOverOneMinute,
    ];
    if (reasons.isNotEmpty) {
      return AlesFlightResult(
        outcome: FlightOutcome.zero,
        zeroReasons: reasons,
        flightPenalty: flightPenalty,
      );
    }
    if (time == null) {
      return AlesFlightResult(
        outcome: FlightOutcome.zero,
        flightPenalty: flightPenalty,
      );
    }

    return AlesFlightResult(
      outcome: FlightOutcome.scored,
      flightPoints: rules.flightPoints(time),
      landingBonus: landingBonus,
      overflightSeconds: rules.overflightSeconds(time),
      flightPenalty: flightPenalty,
    );
  }

  /// The parsed options of a contest's [overrides] over the defaults.
  AlesOptions options([Map<String, Object?>? overrides]) =>
      AlesOptions.fromMap(resolveOptions(overrides));
}
