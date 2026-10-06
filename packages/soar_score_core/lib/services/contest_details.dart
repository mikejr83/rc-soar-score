/// The identity, schedule and location of a contest that a director can
/// change after creation. The timezone is fixed at creation.
class ContestDetails {
  const ContestDetails({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    this.host,
    this.city,
    this.state,
    this.country,
  });

  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? host;
  final String? city;
  final String? state;
  final String? country;
}
