/// One row of the Overall Individual Results table as of a selected round.
class PilotStandingRow {
  const PilotStandingRow({
    required this.pilotKey,
    required this.place,
    required this.isTied,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.overallScore,
    required this.percentOfWinner,
    required this.rawTotal,
    required this.roundScores,
    required this.droppedRounds,
    required this.penaltyTotal,
  });

  final String pilotKey;
  final int place;
  final bool isTied;

  /// Empty for a redacted pilot.
  final String firstName;
  final String lastName;
  final String country;
  final double overallScore;

  /// 0 to 100; 100 for the winner.
  final double percentOfWinner;
  final double rawTotal;

  /// Round ordinal to that round's score; a round without a flight is absent.
  final Map<int, double> roundScores;
  final Set<int> droppedRounds;
  final double penaltyTotal;

  String get name {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Pilot withheld' : full;
  }
}
