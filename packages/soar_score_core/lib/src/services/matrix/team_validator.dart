/// Validates team protection constraints.
class TeamValidator {
  /// Check if groupsPerRound is sufficient for team protection.
  bool validateGroupCount({
    required Map<String, int> pilotTeams,
    required int groupsPerRound,
  }) {
    return getMaxTeamSize(pilotTeams) <= groupsPerRound;
  }

  /// Get the maximum team size from pilot-team assignments.
  int getMaxTeamSize(Map<String, int> pilotTeams) {
    final teamSizes = <int, int>{};
    for (final teamId in pilotTeams.values) {
      teamSizes[teamId] = (teamSizes[teamId] ?? 0) + 1;
    }
    if (teamSizes.isEmpty) return 0;
    return teamSizes.values.reduce((a, b) => a > b ? a : b);
  }

  /// Get team sizes for each team.
  Map<int, int> getTeamSizes(Map<String, int> pilotTeams) {
    final teamSizes = <int, int>{};
    for (final teamId in pilotTeams.values) {
      teamSizes[teamId] = (teamSizes[teamId] ?? 0) + 1;
    }
    return teamSizes;
  }
}