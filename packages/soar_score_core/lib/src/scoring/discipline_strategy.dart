import '../models/contest_config.dart';
import '../models/flight.dart';
import '../models/score_result.dart';

/// Strategy interface for discipline-specific scoring.
abstract class DisciplineScoringStrategy {
  /// Compute the raw score for a flight based on its components.
  ScoreResult computeRawScore(Flight flight, ContestScoringConfig config);
}
