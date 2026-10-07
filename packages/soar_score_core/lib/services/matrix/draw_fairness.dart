import 'basic_draw.dart';

/// The fairness report stored with a draw: how often pilots meet.
///
/// Counts only pairs that can meet: with [teamProtection], teammates never
/// share a group, so they are left out of the histogram, the unmet opponent
/// count and the mean absolute deviation (`matrix-draw.md` section 3). The
/// report holds the maximum duplicate matchups, the matchup histogram (with
/// `0` for pairs that never meet), the unmet opponent count, the number of
/// feasible pairs and the mean absolute deviation of the meeting counts from
/// their mean. The lane uniformity index and the overall score come with the
/// optimizer.
Map<String, Object?> drawFairness(
  List<List<List<DrawSlot>>> rounds, {
  required bool teamProtection,
}) {
  final meetings = <String, int>{};
  final pilots = <String, Object?>{};
  for (final round in rounds) {
    for (final group in round) {
      final slots = [...group]
        ..sort(
          (a, b) => a.pilot.participationId.value.compareTo(
            b.pilot.participationId.value,
          ),
        );
      for (final slot in slots) {
        pilots[slot.pilot.participationId.value] = slot.pilot.teamId;
      }
      for (var i = 0; i < slots.length; i++) {
        for (var j = i + 1; j < slots.length; j++) {
          final key =
              '${slots[i].pilot.participationId.value}|'
              '${slots[j].pilot.participationId.value}';
          meetings[key] = (meetings[key] ?? 0) + 1;
        }
      }
    }
  }

  // Pairs teammates make: they cannot meet under team protection.
  var forbidden = 0;
  if (teamProtection) {
    final teamSizes = <Object, int>{};
    for (final team in pilots.values) {
      if (team != null) {
        teamSizes[team] = (teamSizes[team] ?? 0) + 1;
      }
    }
    for (final size in teamSizes.values) {
      forbidden += size * (size - 1) ~/ 2;
    }
  }
  final feasible = pilots.length * (pilots.length - 1) ~/ 2 - forbidden;
  final unmet = feasible - meetings.length;

  final histogram = <int, int>{if (unmet > 0) 0: unmet};
  var maxDuplicates = 0;
  var total = 0;
  for (final count in meetings.values) {
    histogram[count] = (histogram[count] ?? 0) + 1;
    total += count;
    if (count > maxDuplicates) {
      maxDuplicates = count;
    }
  }
  var deviation = 0.0;
  if (feasible > 0) {
    final mean = total / feasible;
    deviation += unmet * mean;
    for (final count in meetings.values) {
      deviation += (count - mean).abs();
    }
    deviation /= feasible;
  }
  final sorted = histogram.keys.toList()..sort();
  return {
    'feasible_pairs': feasible,
    'max_duplicate_matchups': maxDuplicates,
    'matchup_histogram': {for (final k in sorted) '$k': histogram[k]},
    'unmet_opponent_count': unmet,
    'mean_absolute_deviation': deviation,
  };
}
