import 'package:soar_score_core/soar_score_core.dart';

/// F3J scoring: working time, 30-point penalty for late landing,
/// no over-flight penalty (time stops at working time end).
class F3JScoringStrategy implements DisciplineScoringStrategy {
  @override
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    final f3jFlight = flight as F3JFlight;

    // Check zero conditions
    if (f3jFlight.zeroReason != null) {
      return ScoreResult(
        rawScore: 0,
        groupScore: 0,
        isZeroScore: true,
        zeroReason: f3jFlight.zeroReason!.label,
      );
    }

    // F3J: time stops at working time end
    final workingTime = config.f3jWorkingTimeSeconds ?? config.targetTimeSeconds;
    final duration = f3jFlight.durationSeconds > workingTime
        ? workingTime
        : f3jFlight.durationSeconds;

    double flightScore = duration * config.pointsPerSecond;

    // Add landing bonus
    if (config.groupScoreType == GroupScoreType.normalized) {
      flightScore += f3jFlight.landingBonus ?? 0;
    }

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}
