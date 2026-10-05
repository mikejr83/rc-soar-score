import 'package:equatable/equatable.dart';

import '../../enums/group_score_mode.dart';
import '../../enums/rounding_mode.dart';
import '../../errors/scoring_validation_error.dart';
import '../group/group_score_options.dart';
import '../profile/scoring_issue.dart';

/// Seconds past the target time that an over-flight stays scorable.
const alesOverflightWindowSeconds = 60;

/// The resolved ALES contest options, parsed and checked.
///
/// Keys follow `plan/data-model/examples/disciplines/ales.md` and
/// `plan/data-model/contest-options.md`. Motor restart is always allowed in
/// ALES, so there is no option for it.
class AlesOptions extends Equatable {
  const AlesOptions._({
    required this.targetTimeSeconds,
    required this.pointsPerSecond,
    required this.timeDecimals,
    required this.groupScore,
  });

  /// Parses [options]; throws [ScoringValidationError] for bad values.
  factory AlesOptions.fromMap(Map<String, Object?> options) {
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

    final target = number(
      'target_time',
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
    return AlesOptions._(
      targetTimeSeconds: target!.toDouble(),
      pointsPerSecond: pointsPerSecond!.toDouble(),
      timeDecimals: fractionalSeconds!,
      groupScore: GroupScoreOptions(
        mode: mode!,
        roundingMode: rounding!,
        decimalPlaces: decimals!,
      ),
    );
  }

  final double targetTimeSeconds;
  final double pointsPerSecond;

  /// Decimal places kept for a flown time, 0 to 3.
  final int timeDecimals;
  final GroupScoreOptions groupScore;

  /// The latest flown time that is still scorable without the over-flight
  /// status: the target time plus one minute.
  double get latestScorableSeconds =>
      targetTimeSeconds + alesOverflightWindowSeconds;

  @override
  List<Object?> get props => [
    targetTimeSeconds,
    pointsPerSecond,
    timeDecimals,
    groupScore,
  ];
}
