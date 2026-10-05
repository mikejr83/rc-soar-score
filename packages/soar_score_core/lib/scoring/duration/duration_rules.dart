import 'package:equatable/equatable.dart';

import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';

/// Time-to-points rules shared by the duration disciplines.
class DurationRules extends Equatable {
  DurationRules({
    this.pointsPerSecond = 1,
    required this.workingTimeSeconds,
    this.timeDecimals = 0,
  }) {
    if (!pointsPerSecond.isFinite || pointsPerSecond < 0) {
      throw ArgumentError.value(pointsPerSecond, 'pointsPerSecond');
    }
    if (!workingTimeSeconds.isFinite || workingTimeSeconds <= 0) {
      throw ArgumentError.value(workingTimeSeconds, 'workingTimeSeconds');
    }
    if (timeDecimals < 0 || timeDecimals > 3) {
      throw ArgumentError.value(timeDecimals, 'timeDecimals', 'must be 0 to 3');
    }
  }

  final double pointsPerSecond;

  /// The working time cap: a flown time may never reach it.
  final double workingTimeSeconds;

  /// Decimal places kept for a flown time, 0 to 3.
  final int timeDecimals;

  /// Flight points for [seconds] flown: `points per second * seconds`.
  ///
  /// The time is never rounded or repaired. A negative time, a time that is
  /// not below the working time, or one with more decimals than
  /// [timeDecimals] is rejected with a [ScoringValidationError].
  double flightPoints(double seconds) {
    final issues = <ScoringIssue>[
      if (!seconds.isFinite || seconds < 0)
        const ScoringIssue(
          code: 'out_of_range',
          fieldId: 'time',
          message: 'Time must not be negative.',
        )
      else if (seconds >= workingTimeSeconds)
        const ScoringIssue(
          code: 'out_of_range',
          fieldId: 'time',
          message: 'Time must be less than the working time.',
        )
      else if (!_withinPrecision(seconds))
        ScoringIssue(
          code: 'too_precise',
          fieldId: 'time',
          message: 'Time allows at most $timeDecimals decimal places.',
        ),
    ];
    if (issues.isNotEmpty) throw ScoringValidationError(issues);
    return pointsPerSecond * seconds;
  }

  bool _withinPrecision(double seconds) {
    var scale = 1.0;
    for (var i = 0; i < timeDecimals; i++) {
      scale *= 10;
    }
    final scaled = seconds * scale;
    return (scaled - scaled.roundToDouble()).abs() <= 1e-9;
  }

  @override
  List<Object?> get props => [
    pointsPerSecond,
    workingTimeSeconds,
    timeDecimals,
  ];
}
