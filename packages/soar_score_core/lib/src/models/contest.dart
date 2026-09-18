/// Represents a soaring contest.
class Contest {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String location;

  Contest({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
  });
}