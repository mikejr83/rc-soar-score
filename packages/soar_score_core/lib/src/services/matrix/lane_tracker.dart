import '../../models/matrix/round_assignment.dart';

/// Tracks lane assignments across rounds for fairness metrics.
class LaneTracker {
  final Map<String, Map<int, int>> _laneCounts = {};

  void recordAssignments(List<MatrixPilotAssignment> assignments) {
    for (final a in assignments) {
      if (!_laneCounts.containsKey(a.pilotId)) {
        _laneCounts[a.pilotId] = {};
      }
      _laneCounts[a.pilotId]![a.laneNumber] =
          (_laneCounts[a.pilotId]![a.laneNumber] ?? 0) + 1;
    }
  }

  Map<String, Map<int, int>> get laneCounts => _laneCounts;

  void initializeForPilots(List<String> pilotIds) {
    for (final pilotId in pilotIds) {
      if (!_laneCounts.containsKey(pilotId)) {
        _laneCounts[pilotId] = {};
      }
    }
  }
}