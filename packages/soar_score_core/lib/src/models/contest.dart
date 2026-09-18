/// Represents a soaring contest.
///
/// A contest is the private source-of-truth aggregate for one radio-controlled
/// soaring event. It tracks multiple independent control states rather than a
/// single status field.
class Contest {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String hostVenue;
  final String? city;
  final String? stateProvince;
  final String? country;
  final String? timezone;
  final String? ownerAccountId;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  Contest({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.hostVenue,
    this.city,
    this.stateProvince,
    this.country,
    this.timezone,
    this.ownerAccountId,
    required this.createdAt,
    required this.lastModifiedAt,
  });
}