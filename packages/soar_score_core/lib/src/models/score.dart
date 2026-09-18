/// Represents a score for a flight.
class Score {
  final String id;
  final String flightId;
  final String pilotId;
  final double points;
  final int rank;

  Score({
    required this.id,
    required this.flightId,
    required this.pilotId,
    required this.points,
    required this.rank,
  });
}