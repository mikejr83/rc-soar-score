import 'results_snapshot.dart';
import 'team_pilot.dart';

/// Everything the team overview shows for one contest and helper.
class TeamOverview {
  const TeamOverview({
    required this.contestName,
    required this.teamName,
    required this.pilots,
    required this.standings,
  });

  final String contestName;
  final String teamName;
  final List<TeamPilot> pilots;

  /// Every team, with the helper's own marked `isYou`.
  final List<StandingLine> standings;
}
