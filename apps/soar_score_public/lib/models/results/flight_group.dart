import 'flight_score_row.dart';

/// One flight group of a round in the Flight Group Scores view: its flights
/// by group score, highest first.
class FlightGroup {
  const FlightGroup({
    required this.round,
    required this.group,
    required this.reflight,
    required this.flights,
  });

  final int round;
  final int group;

  /// The re-flight ordinal, or null for the group's original flight.
  final int? reflight;
  final List<FlightScoreRow> flights;

  String get title =>
      reflight == null ? 'Group $group' : 'Group $group, re-flight $reflight';

  /// True when any flight carries raw score components (#456).
  bool get hasRawComponents => flights.any((f) => f.rawComponents.isNotEmpty);

  /// The raw component keys other than the flight time, in first-seen order.
  List<String> get detailKeys => {
    for (final f in flights)
      for (final key in f.rawComponents.keys)
        if (key != FlightScoreRow.timeKey) key,
  }.toList();
}
