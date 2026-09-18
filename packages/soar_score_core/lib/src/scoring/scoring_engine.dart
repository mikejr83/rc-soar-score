import '../models/flight.dart';
import '../models/score.dart';

/// Computes scores for flights based on distance and duration.
class ScoringEngine {
  /// Calculate the score for a flight.
  Score calculateScore(Flight flight) {
    // Stub: basic scoring logic placeholder
    final points = flight.distanceKm * 10.0;
    return Score(
      id: 'score-${flight.id}',
      flightId: flight.id,
      pilotId: flight.pilotId,
      points: points,
      rank: 0,
    );
  }
}