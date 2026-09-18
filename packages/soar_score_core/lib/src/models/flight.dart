/// Represents a flight during a contest.
class Flight {
  final String id;
  final String pilotId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double durationMinutes;

  Flight({
    required this.id,
    required this.pilotId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationMinutes,
  });
}