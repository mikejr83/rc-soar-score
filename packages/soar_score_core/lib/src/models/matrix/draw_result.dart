import 'round_assignment.dart';

/// The result of a matrix draw operation.
class DrawResult {
  final List<RoundAssignment> rounds;
  final Map<String, int> pilotTeamIds;
  final int groupsPerRound;
  final int roundsRequested;
  final Map<String, int> matchupCounts;
  final int maxDuplicateMatchups;
  final List<int> matchupHistogram;
  final Map<String, Map<int, int>> laneAssignments;
  final int totalIterations;

  DrawResult({
    required this.rounds,
    required this.pilotTeamIds,
    required this.groupsPerRound,
    required this.roundsRequested,
    required this.matchupCounts,
    required this.maxDuplicateMatchups,
    required this.matchupHistogram,
    required this.laneAssignments,
    required this.totalIterations,
  });
}