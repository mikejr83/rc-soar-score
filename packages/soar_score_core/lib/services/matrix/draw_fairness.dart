import 'basic_draw.dart';
import 'lane_stats.dart';
import 'matchup_stats.dart';

/// The fairness report stored with a draw: how often pilots meet.
///
/// Counts only pairs that can meet: with [teamProtection], teammates never
/// share a group, so they are left out of every figure (`matrix-draw.md`
/// section 3). The report holds the feasible pair count, the maximum
/// duplicate matchups, the matchup histogram (with `0` for pairs that never
/// meet), the unmet opponent count and the mean absolute deviation of the
/// meeting counts from their mean. When the draw has lanes it also holds the
/// lane uniformity index and the lane penalty. The overall fairness score is added by the engine,
/// which knows the random baseline.
Map<String, Object?> drawFairness(
  List<List<List<DrawSlot>>> rounds, {
  required bool teamProtection,
}) {
  final stats = MatchupStats.of(rounds, teamProtection: teamProtection);
  final keys = stats.histogram.keys.toList()..sort();
  final lanes = LaneStats.of(rounds);
  return {
    'feasible_pairs': stats.feasiblePairs,
    'max_duplicate_matchups': stats.maxDuplicates,
    'matchup_histogram': {for (final k in keys) '$k': stats.histogram[k]},
    'unmet_opponent_count': stats.unmet,
    'mean_absolute_deviation': stats.meanAbsoluteDeviation,
    'lane_uniformity_index': ?lanes?.uniformityIndex,
    'lane_cost': ?lanes?.cost,
  };
}
