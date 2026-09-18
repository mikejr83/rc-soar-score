import '../models/contest_config.dart';
import '../models/flight.dart';
import '../models/score_result.dart';
import 'discipline_strategy.dart';

/// Computes scores for flights based on discipline-specific rules.
class ScoringEngine {
  final Map<Discipline, DisciplineScoringStrategy> _strategies = {};

  ScoringEngine() {
    // Register strategies for each discipline
    _strategies[Discipline.ales] = SimpleDurationScoringStrategy();
    _strategies[Discipline.thermalDuration] = SimpleDurationScoringStrategy();
    _strategies[Discipline.f3j] = F3JScoringStrategy();
    _strategies[Discipline.f5j] = F5JScoringStrategy();
  }

  /// Compute the raw score for a single flight.
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config) {
    final strategy = _strategies[config.discipline];
    if (strategy == null) {
      throw UnsupportedError('No scoring strategy for ${config.discipline}');
    }
    return strategy.computeRawScore(flight, config);
  }

  /// Normalize scores within a group.
  ///
  /// The pilot with the highest raw score receives 1000 points. All other
  /// scores are normalized proportionally. Zero scores remain at 0.
  GroupScores normalizeGroupScores(
      List<Flight> flights, ContestScoringConfig config) {
    final results = <ScoreResult>[];

    for (final flight in flights) {
      results.add(computeRawScore(flight, config));
    }

    // Find highest non-zero raw score for normalization
    double highestRaw = 0;
    for (final result in results) {
      if (!result.isZeroScore && result.rawScore > highestRaw) {
        highestRaw = result.rawScore;
      }
    }

    // If all scores are zero, all get 0
    if (highestRaw == 0) {
      return GroupScores(results);
    }

    // Normalize each score to 0-1000
    final normalized = <ScoreResult>[];
    for (final result in results) {
      if (result.isZeroScore) {
        normalized.add(result);
      } else {
        final groupScore = (result.rawScore / highestRaw) * 1000.0;
        normalized.add(ScoreResult(
          rawScore: result.rawScore,
          groupScore: groupScore,
          isZeroScore: result.isZeroScore,
          zeroReason: result.zeroReason,
        ));
      }
    }

    return GroupScores(normalized);
  }
}