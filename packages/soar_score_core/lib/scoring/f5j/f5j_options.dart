import 'package:equatable/equatable.dart';

import '../../enums/group_score_mode.dart';
import '../../enums/rounding_mode.dart';
import '../../errors/scoring_validation_error.dart';
import '../duration/duration_rules.dart';
import '../group/group_score_options.dart';
import '../profile/scoring_issue.dart';
import 'f5j_motor_restart_mode.dart';

/// The resolved F5J contest options, parsed and checked.
///
/// Keys follow `plan/data-model/examples/disciplines/f5j.md` and
/// `plan/data-model/contest-options.md`.
class F5jOptions extends Equatable {
  const F5jOptions._({
    required this.duration,
    required this.referenceLaunchHeight,
    required this.minorPenaltyPerMeter,
    required this.majorPenaltyPerMeter,
    required this.motorRestartMode,
    required this.groupScore,
  });

  /// Parses [options]; throws [ScoringValidationError] for bad values.
  factory F5jOptions.fromMap(Map<String, Object?> options) {
    final issues = <ScoringIssue>[];

    void bad(String key, String message) => issues.add(
      ScoringIssue(code: 'invalid_option', fieldId: key, message: message),
    );

    num? number(String key, bool Function(num) ok, String rule) {
      final value = options[key];
      if (value is num && value.isFinite && ok(value)) return value;
      bad(key, '"$key" must be $rule.');
      return null;
    }

    int? whole(String key, bool Function(int) ok, String rule) {
      final value = options[key];
      if (value is int && ok(value)) return value;
      bad(key, '"$key" must be $rule.');
      return null;
    }

    T? choice<T>(String key, List<T> values, String Function(T) text) {
      for (final value in values) {
        if (text(value) == options[key]) return value;
      }
      bad(key, '"$key" has a value that is not allowed.');
      return null;
    }

    final workingTime = number(
      'working_time',
      (v) => v > 0 && v < 3600,
      'above 0 and below 3600',
    );
    final pointsPerSecond = number(
      'points_per_second',
      (v) => v > 0,
      'above 0',
    );
    final fractionalSeconds = whole(
      'fractional_seconds',
      (v) => v >= 0 && v <= 3,
      '0 to 3',
    );
    final referenceHeight = number(
      'reference_launch_height',
      (v) => v > 0,
      'above 0',
    );
    final minor = number(
      'minor_penalty_per_meter',
      (v) => v >= 0,
      'at least 0',
    );
    final major = number(
      'major_penalty_per_meter',
      (v) => v >= 0,
      'at least 0',
    );
    final restart = choice(
      'motor_restart_mode',
      F5jMotorRestartMode.values,
      (m) => m.json,
    );
    final mode = choice(
      'group_score_mode',
      GroupScoreMode.values,
      (m) => m.json,
    );
    final rounding = choice(
      'rounding_mode',
      RoundingMode.values,
      (m) => m.json,
    );
    final decimals = whole('decimal_places', (v) => v >= 0 && v <= 3, '0 to 3');

    if (issues.isNotEmpty) throw ScoringValidationError(issues);
    return F5jOptions._(
      duration: DurationRules(
        pointsPerSecond: pointsPerSecond!.toDouble(),
        workingTimeSeconds: workingTime!.toDouble(),
        timeDecimals: fractionalSeconds!,
      ),
      referenceLaunchHeight: referenceHeight!,
      minorPenaltyPerMeter: minor!.toDouble(),
      majorPenaltyPerMeter: major!.toDouble(),
      motorRestartMode: restart!,
      groupScore: GroupScoreOptions(
        mode: mode!,
        roundingMode: rounding!,
        decimalPlaces: decimals!,
      ),
    );
  }

  final DurationRules duration;
  final num referenceLaunchHeight;
  final double minorPenaltyPerMeter;
  final double majorPenaltyPerMeter;
  final F5jMotorRestartMode motorRestartMode;
  final GroupScoreOptions groupScore;

  @override
  List<Object?> get props => [
    duration,
    referenceLaunchHeight,
    minorPenaltyPerMeter,
    majorPenaltyPerMeter,
    motorRestartMode,
    groupScore,
  ];
}
