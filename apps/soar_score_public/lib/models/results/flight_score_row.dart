/// One pilot's flight in a group.
class FlightScoreRow {
  const FlightScoreRow({
    required this.pilotKey,
    required this.name,
    required this.country,
    required this.outcome,
    required this.rawComponents,
    required this.landingPoints,
    required this.rawPoints,
    required this.groupScore,
    required this.penaltyPoints,
    required this.isSelected,
  });

  /// The F5J profile's flight time field (`time_flown`); other disciplines
  /// use the same key or none.
  static const String timeKey = 'time_flown';

  final String pilotKey;
  final String name;
  final String country;
  final String outcome;

  /// The discipline's raw inputs, keyed by score field; empty until the
  /// projection carries them (#456).
  final Map<String, Object?> rawComponents;
  final double landingPoints;
  final double rawPoints;
  final double groupScore;
  final double penaltyPoints;

  /// False for a flight replaced by a re-flight.
  final bool isSelected;

  Object? get time => rawComponents[timeKey];
}
