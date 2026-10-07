import 'dart:math' as math;

import 'basic_draw.dart';

/// How evenly the pilots of a draw fly from each lane (`matrix-draw.md`
/// sections 3.2 and 3.3).
///
/// Lanes run from 1 to the largest group size `L`. Each pilot flies once a
/// round, so over `R` rounds the target is `R / L` flights from each lane.
class LaneStats {
  LaneStats._({
    required this.laneCount,
    required this.rounds,
    required this.counts,
  });

  /// The lane statistics of [rounds], or `null` when the draw has no lanes.
  static LaneStats? of(List<List<List<DrawSlot>>> rounds) {
    var laneCount = 0;
    for (final round in rounds) {
      for (final group in round) {
        if (group.length > laneCount) laneCount = group.length;
      }
    }
    final used = <String, List<int>>{};
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
    return LaneStats._(
      laneCount: laneCount,
      rounds: rounds.length,
      counts: [for (final row in used.values) ...row],
    );
  }

  /// The number of lanes, `L`.
  final int laneCount;

  /// The number of rounds, `R`.
  final int rounds;

  /// How often each pilot flew from each lane (pilots times lanes entries).
  final List<int> counts;

  int get _pilots => counts.length ~/ laneCount;

  /// The target flights per lane, `R / L`.
  double get target => rounds / laneCount;

  /// The lane penalty `J_lane`: the sum over pilots and lanes of
  /// `(count - R / L)^2`.
  double get cost {
    final lambda = target;
    var total = 0.0;
    for (final count in counts) {
      total += (count - lambda) * (count - lambda);
    }
    return total;
  }

  /// The lowest `J_lane` possible: flight counts are whole numbers, so with
  /// `f` the fractional part of `R / L` each pilot costs at least
  /// `L * f * (1 - f)`.
  double get idealCost {
    final f = target - target.floorToDouble();
    return _pilots * laneCount * f * (1 - f);
  }

  /// The lane uniformity index: the standard deviation of lane usage across
  /// all pilots and lanes. Zero when every count is the same.
  double get uniformityIndex {
    final mean = counts.fold(0, (a, b) => a + b) / counts.length;
    var squares = 0.0;
    for (final count in counts) {
      squares += (count - mean) * (count - mean);
    }
    return math.sqrt(squares / counts.length);
  }
}
