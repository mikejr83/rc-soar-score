/// One line of an overall standings table.
class StandingLine {
  const StandingLine({
    required this.place,
    required this.name,
    required this.score,
    this.isYou = false,
    this.tied = false,
  });

  final String place;
  final String name;
  final String score;
  final bool isYou;
  final bool tied;
}

/// The overall results as of a round: the viewer's own place and the tables.
class ResultsSnapshot {
  const ResultsSnapshot({
    required this.round,
    required this.ordinal,
    required this.score,
    required this.pilots,
    required this.teams,
  });

  /// The round the standings are as of.
  final int round;

  /// The viewer's place, such as `3rd`.
  final String ordinal;
  final String score;
  final List<StandingLine> pilots;
  final List<StandingLine> teams;
}
