import 'package:soar_score_core/soar_score_core.dart';

/// Simple duration scoring: fly to target time, earn points per second,
/// penalty for over-flying, landing bonus added per group score type.
class SimpleDurationScoringStrategy implements DisciplineScoringStrategy {
  @override
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    double duration = 0;
    int? landingBonus;
    ZeroReason? zeroReason;

    if (flight is ThermalDurationFlight) {
      duration = flight.durationSeconds;
      landingBonus = flight.landingBonus;
      zeroReason = flight.zeroReason;
    }

    // Check zero conditions
    if (zeroReason != null) {
      return ScoreResult(
        rawScore: 0,
        groupScore: 0,
        isZeroScore: true,
        zeroReason: zeroReason.label,
      );
    }

    // Compute raw flight score
    double flightScore = duration * config.pointsPerSecond;

    // Penalty for over-flying (flew past target time)
    if (duration > config.targetTimeSeconds) {
      final overflightSeconds = duration - config.targetTimeSeconds;
      flightScore =
          config.targetTimeSeconds * config.pointsPerSecond -
          (overflightSeconds * config.pointsPerSecond);
    }

    if (config.groupScoreType == GroupScoreType.normalized && landingBonus != null) {
      flightScore += landingBonus;
    }

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}
