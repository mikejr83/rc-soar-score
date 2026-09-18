import '../../models/matrix/round_assignment.dart';

/// Tracks matchup history between pilots across rounds.
class MatchupTracker {
  final Map<String, int> _pairCounts = {};

  /// Count of times each pilot pair has flown together.
  Map<String, int> get pairCounts => Map.unmodifiable(_pairCounts);

  void recordMatchups(List<MatrixPilotAssignment> assignments) {
    final groups = _groupByAssignment(assignments);

    for (final groupPilots in groups.values) {
      for (int i = 0; i < groupPilots.length; i++) {
        for (int j = i + 1; j < groupPilots.length; j++) {
          final key = _pairKey(groupPilots[i], groupPilots[j]);
          _pairCounts[key] = (_pairCounts[key] ?? 0) + 1;
        }
      }
    }
  }

  /// Get current matchup count for a pair.
  int getPairCount(String pilotA, String pilotB) {
    return _pairCounts[_pairKey(pilotA, pilotB)] ?? 0;
  }

  Map<int, List<String>> _groupByAssignment(List<MatrixPilotAssignment> assignments) {
    final groups = <int, List<String>>{};
    for (final a in assignments) {
      if (!groups.containsKey(a.groupNumber)) {
        groups[a.groupNumber] = [];
      }
      groups[a.groupNumber]!.add(a.pilotId);
    }
    return groups;
  }

  String _pairKey(String a, String b) {
    if (a.compareTo(b) < 0) return '$a-$b';
    return '$b-$a';
  }
}