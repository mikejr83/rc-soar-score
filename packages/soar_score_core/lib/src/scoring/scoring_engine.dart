import '../models/flight.dart';
import '../models/score.dart';

/// Computes scores for flights.
///
/// Stub implementation - to be replaced with actual discipline-specific
/// scoring logic.
class ScoringEngine {
  /// Calculate the score for a flight.
  Score calculateScore(Flight flight) {
    // Stub: basic scoring logic placeholder
    return Score(
      id: 'score-${flight.id}',
      placeholderId: flight.id,
      rawComponents: {'flightId': flight.id, 'pilotId': flight.pilotId},
      submissionTime: DateTime.now(),
      clientMutationId: 'stub-${flight.id}',
      baseScoreRevision: '0',
      configRevision: '0',
      matrixRevision: '0',
      disciplineRulesVersion: '0',
      calculationVersion: '0',
    );
  }
}