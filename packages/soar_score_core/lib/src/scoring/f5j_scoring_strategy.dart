import 'package:soar_score_core/soar_score_core.dart';

/// F5J scoring: working time, height penalty, motor restart handling.
class F5JScoringStrategy implements DisciplineScoringStrategy {
  @override
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    final f5jFlight = flight as F5JFlight;

    // Check motor restart
    if (f5jFlight.zeroReason != null && f5jFlight.zeroReason is MotorRestart) {
      return ScoreResult(
        rawScore: 0,
        groupScore: 0,
        isZeroScore: true,
        zeroReason: f5jFlight.zeroReason!.label,
      );
    }

    // Check other zero conditions
    if (f5jFlight.zeroReason != null) {
      return ScoreResult(
        rawScore: 0,
        groupScore: 0,
        isZeroScore: true,
        zeroReason: f5jFlight.zeroReason!.label,
      );
    }

    // F5J: time stops at working time end
    final workingTime =
        config.f5jWorkingTimeSeconds ?? config.targetTimeSeconds;
    final duration = f5jFlight.durationSeconds > workingTime
        ? workingTime
        : f5jFlight.durationSeconds;

    double flightScore = duration * config.pointsPerSecond;

    // Apply height penalty based on launch altitude
    if (f5jFlight.launchAltitudeMeters != null) {
      final altitude = f5jFlight.launchAltitudeMeters!;
      final penaltyPerMeter = config.f5jHeightPenaltyPerMeter ?? 0.5;
      final aboveRefPenalty = config.f5jAboveReferencePenaltyPerMeter ?? 3.0;
      final referenceAlt = config.f5jReferenceAltitudeMeters ?? 200.0;

      double heightPenaltyPoints;
      if (altitude <= referenceAlt) {
        // Below reference altitude: minor penalty per meter
        heightPenaltyPoints = altitude * penaltyPerMeter;
      } else {
        // Above reference altitude: minor penalty for first referenceAlt
        // meters, major penalty for the rest
        heightPenaltyPoints =
            referenceAlt * penaltyPerMeter +
            (altitude - referenceAlt) * aboveRefPenalty;
      }
      flightScore -= heightPenaltyPoints;
    }

    // Apply distance penalty
    if (f5jFlight.distancePenaltySeconds != null) {
      flightScore -= f5jFlight.distancePenaltySeconds! * config.pointsPerSecond;
    }

    // Add landing bonus
    if (config.groupScoreType == GroupScoreType.normalized) {
      flightScore += f5jFlight.landingBonus ?? 0;
    }

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}
