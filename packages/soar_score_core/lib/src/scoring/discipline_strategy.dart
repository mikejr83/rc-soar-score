import '../models/contest_config.dart';
import '../models/flight.dart';
import '../models/flights/ales_flight.dart';
import '../models/flights/f3j_flight.dart';
import '../models/flights/f5j_flight.dart';
import '../models/flights/thermal_duration_flight.dart';
import '../models/flights/zero_reason.dart';
import '../models/score_result.dart';

/// Strategy interface for discipline-specific scoring.
abstract class DisciplineScoringStrategy {
  /// Compute the raw score for a flight based on its components.
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config);
}

/// Simple duration scoring: fly to target time, earn points per second,
/// penalty for over-flying, landing bonus added per group score type.
class SimpleDurationScoringStrategy implements DisciplineScoringStrategy {
  @override
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    final duration = flight is AlesFlight
        ? flight.durationSeconds
        : flight is ThermalDurationFlight
            ? flight.durationSeconds
            : (flight as F3JFlight).durationSeconds;

    final zeroReason = flight is AlesFlight
        ? flight.zeroReason
        : flight is ThermalDurationFlight
            ? flight.zeroReason
            : (flight as F3JFlight).zeroReason;

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
      flightScore = config.targetTimeSeconds * config.pointsPerSecond -
          (overflightSeconds * config.pointsPerSecond);
    }

    // No landing bonus at this stage - that's added during group normalization
    // based on group score type

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}

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

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}

/// F5J scoring: working time, height penalty, motor restart handling.
class F5JScoringStrategy implements DisciplineScoringStrategy {
  @override
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    final f5jFlight = flight as F5JFlight;

    // Check motor restart
    if (f5jFlight.zeroReason != null &&
        f5jFlight.zeroReason is MotorRestart) {
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
    final workingTime = config.f5jWorkingTimeSeconds ?? config.targetTimeSeconds;
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
        heightPenaltyPoints = referenceAlt * penaltyPerMeter +
            (altitude - referenceAlt) * aboveRefPenalty;
      }
      flightScore -= heightPenaltyPoints;
    }

    // Apply distance penalty
    if (f5jFlight.distancePenaltySeconds != null) {
      flightScore -= f5jFlight.distancePenaltySeconds! * config.pointsPerSecond;
    }

    // Add landing bonus
    flightScore += f5jFlight.landingBonus;

    return ScoreResult(rawScore: flightScore, groupScore: 0);
  }
}