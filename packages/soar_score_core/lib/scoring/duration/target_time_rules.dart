import 'package:equatable/equatable.dart';

import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';
import 'time_precision.dart';

/// Time-to-points rules for a task flown to a target time.
///
/// Flying under the target scores `points per second * time`. Flying over it
/// scores as if the same number of seconds had been flown under it, so 602 s
/// on a 600 s target scores like 598 s. The result never drops below zero.
class TargetTimeRules extends Equatable {
  TargetTimeRules({
    this.pointsPerSecond = 1,
    required this.targetTimeSeconds,
    this.timeDecimals = 0,
    this.overflightLimitSeconds = 60,
  }) {
    if (!pointsPerSecond.isFinite || pointsPerSecond < 0) {
      throw ArgumentError.value(pointsPerSecond, 'pointsPerSecond');
    }
    if (!targetTimeSeconds.isFinite || targetTimeSeconds <= 0) {
      throw ArgumentError.value(targetTimeSeconds, 'targetTimeSeconds');
    }
    if (timeDecimals < 0 || timeDecimals > 3) {
      throw ArgumentError.value(timeDecimals, 'timeDecimals', 'must be 0 to 3');
    }
    if (!overflightLimitSeconds.isFinite || overflightLimitSeconds < 0) {
      throw ArgumentError.value(
        overflightLimitSeconds,
        'overflightLimitSeconds',
      );
    }
  }

  final double pointsPerSecond;
  final double targetTimeSeconds;

  /// Decimal places kept for a flown time, 0 to 3.
  final int timeDecimals;

  /// How far past the target a flight may land before it counts as an
  /// over-flight; what that costs is up to the discipline.
  final double overflightLimitSeconds;

  /// Seconds flown past the target; zero at or under it.
  double overflightSeconds(double seconds) {
    _check(seconds);
    return seconds > targetTimeSeconds ? seconds - targetTimeSeconds : 0;
  }

  /// Whether [seconds] is more than [overflightLimitSeconds] past the target.
  bool isOverflightOverLimit(double seconds) =>
      overflightSeconds(seconds) > overflightLimitSeconds;

  /// The seconds that count: the time flown, less the over-flight counted
  /// again against it. Never below zero.
  double effectiveSeconds(double seconds) {
    final effective = seconds - 2 * overflightSeconds(seconds);
    return effective < 0 ? 0 : effective;
  }

  /// Flight points for [seconds] flown: `points per second * effective time`.
  ///
  /// The time is never rounded or repaired. A negative or non-finite time, or
  /// one with more decimals than [timeDecimals], is rejected with a
  /// [ScoringValidationError]. A time past the target is allowed at any
  /// length; the caller decides what an over-flight past the limit means.
  double flightPoints(double seconds) =>
      pointsPerSecond * effectiveSeconds(seconds);

  void _check(double seconds) {
    final issues = <ScoringIssue>[
      if (!seconds.isFinite || seconds < 0)
        const ScoringIssue(
          code: 'out_of_range',
          fieldId: 'time',
          message: 'Time must not be negative.',
        )
      else if (!hasAtMostDecimals(seconds, timeDecimals))
        ScoringIssue(
          code: 'too_precise',
          fieldId: 'time',
          message: 'Time allows at most $timeDecimals decimal places.',
        ),
    ];
    if (issues.isNotEmpty) throw ScoringValidationError(issues);
  }

  @override
  List<Object?> get props => [
    pointsPerSecond,
    targetTimeSeconds,
    timeDecimals,
    overflightLimitSeconds,
  ];
}
