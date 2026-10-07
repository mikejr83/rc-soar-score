import 'basic_draw.dart';

/// The fairness report stored with a draw: how often pilots meet.
///
/// Covers the matchup half of `matrix-draw.md` section 5 (maximum duplicate
/// matchups, the matchup histogram and the unmet opponent count). The lane
/// uniformity index and the overall score come with the optimizer.
Map<String, Object?> drawFairness(List<List<List<DrawSlot>>> rounds) {
  final meetings = <String, int>{};
  final pilots = <String>{};
  for (final round in rounds) {
    for (final group in round) {
      final ids = [for (final slot in group) slot.pilot.participationId.value]
        ..sort();
      pilots.addAll(ids);
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final key = '${ids[i]}|${ids[j]}';
          meetings[key] = (meetings[key] ?? 0) + 1;
        }
      }
    }
  }
  final histogram = <int, int>{};
  var maxDuplicates = 0;
  for (final count in meetings.values) {
    histogram[count] = (histogram[count] ?? 0) + 1;
    if (count > maxDuplicates) {
      maxDuplicates = count;
    }
  }
  final pairs = pilots.length * (pilots.length - 1) ~/ 2;
  return {
    'max_duplicate_matchups': maxDuplicates,
    'matchup_histogram': {
      for (final entry in histogram.entries) '${entry.key}': entry.value,
    },
    'unmet_opponent_count': pairs - meetings.length,
  };
}
