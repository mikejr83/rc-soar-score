/// What the contest is configured to show in the grid: a lane or number
/// column, and teams. A contest without lanes, pilot numbers or teams leaves
/// them out.
class ScoreGridOptions {
  const ScoreGridOptions({this.idLabel, this.showTeams = false});

  /// "Lane" or "No." over the first column, or null when there is none.
  final String? idLabel;
  final bool showTeams;

  bool get showId => idLabel != null;
  bool get showsLanes => idLabel == 'Lane';
}
