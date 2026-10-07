import 'dart:math' as math;

import 'basic_draw.dart';
import 'matchup_stats.dart';

/// The fairness report stored with a draw: how often pilots meet.
///
/// Counts only pairs that can meet: with [teamProtection], teammates never
/// share a group, so they are left out of every figure (`matrix-draw.md`
/// section 3). The report holds the feasible pair count, the maximum
/// duplicate matchups, the matchup histogram (with `0` for pairs that never
/// meet), the unmet opponent count and the mean absolute deviation of the
/// meeting counts from their mean. When the draw has lanes it also holds the
/// lane uniformity index. The overall fairness score is added by the engine,
/// which knows the random baseline.
Map<String, Object?> drawFairness(
  List<List<List<DrawSlot>>> rounds, {
  required bool teamProtection,
}) {
  final stats = MatchupStats.of(rounds, teamProtection: teamProtection);
  final keys = stats.histogram.keys.toList()..sort();
  final lanes = _laneUniformity(rounds);
  return {
    'feasible_pairs': stats.feasiblePairs,
    'max_duplicate_matchups': stats.maxDuplicates,
    'matchup_histogram': {for (final k in keys) '$k': stats.histogram[k]},
    'unmet_opponent_count': stats.unmet,
    'mean_absolute_deviation': stats.meanAbsoluteDeviation,
    'lane_uniformity_index': ?lanes,
  };
}

/// The standard deviation of how often each pilot flew from each lane, or
/// `null` when the draw has no lanes. Lanes run from 1 to the largest group
/// size.
double? _laneUniformity(List<List<List<DrawSlot>>> rounds) {
  final used = <String, List<int>>{};
  var laneCount = 0;
  for (final round in rounds) {
    for (final group in round) {
      if (group.length > laneCount) laneCount = group.length;
    }
  }
  for (final round in rounds) {
    for (final group in round) {
      for (final slot in group) {
        final lane = slot.lane;
        if (lane == null) return null;
        used.putIfAbsent(
          slot.pilot.participationId.value,
          () => List<int>.filled(laneCount, 0),
        )[lane - 1]++;
      }
    }
  }
  if (used.isEmpty) return null;
  final counts = [for (final row in used.values) ...row];
  final mean = counts.fold(0, (a, b) => a + b) / counts.length;
  var squares = 0.0;
  for (final count in counts) {
    squares += (count - mean) * (count - mean);
  }
  return math.sqrt(squares / counts.length);
}
