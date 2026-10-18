import 'pilot_standing_row.dart';

/// One team section of the Team Scores table as of a selected round.
class TeamStandingRow {
  const TeamStandingRow({
    required this.teamKey,
    required this.place,
    required this.isTied,
    required this.name,
    required this.teamScore,
    required this.percentOfWinner,
    required this.pilots,
  });

  final String teamKey;
  final int place;
  final bool isTied;
  final String name;
  final double teamScore;

  /// 0 to 100; 100 for the winning team.
  final double percentOfWinner;

  /// The team's pilots that have a standing as of the round, by place.
  final List<PilotStandingRow> pilots;
}
