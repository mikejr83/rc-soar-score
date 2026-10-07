import 'basic_draw.dart';

/// How often the pilots of a draw meet, over the pairs that can meet.
///
/// With team protection, teammates never share a group, so they are not
/// feasible pairs and are left out of every figure (`matrix-draw.md`
/// section 3).
class MatchupStats {
  MatchupStats._({
    required this.feasiblePairs,
    required this.meetingCounts,
    required this.histogram,
  });

  /// The statistics of [rounds].
  factory MatchupStats.of(
    List<List<List<DrawSlot>>> rounds, {
    required bool teamProtection,
  }) {
    final meetings = <String, int>{};
    final teamOf = <String, Object?>{};
    for (final round in rounds) {
      for (final group in round) {
        final ids = [
          for (final slot in group) slot.pilot.participationId.value,
        ];
        for (final slot in group) {
          teamOf[slot.pilot.participationId.value] = slot.pilot.teamId;
        }
        ids.sort();
        for (var i = 0; i < ids.length; i++) {
          for (var j = i + 1; j < ids.length; j++) {
            final key = '${ids[i]}|${ids[j]}';
            meetings[key] = (meetings[key] ?? 0) + 1;
          }
        }
      }
    }
    var forbidden = 0;
    if (teamProtection) {
      final sizes = <Object, int>{};
      for (final team in teamOf.values) {
        if (team != null) {
          sizes[team] = (sizes[team] ?? 0) + 1;
        }
      }
      for (final size in sizes.values) {
        forbidden += size * (size - 1) ~/ 2;
      }
    }
    final feasible = teamOf.length * (teamOf.length - 1) ~/ 2 - forbidden;
    final histogram = <int, int>{};
    for (final count in meetings.values) {
      histogram[count] = (histogram[count] ?? 0) + 1;
    }
    final unmet = feasible - meetings.length;
    if (unmet > 0) {
      histogram[0] = unmet;
    }
    return MatchupStats._(
      feasiblePairs: feasible,
      meetingCounts: meetings.values.toList(),
      histogram: histogram,
    );
  }

  /// The pairs of pilots that can meet.
  final int feasiblePairs;

  /// How often each pair that met did meet (pairs that never met are absent).
  final List<int> meetingCounts;

  /// How many feasible pairs met `n` times, with `0` for pairs that never met.
  final Map<int, int> histogram;

  /// Feasible pairs that never fly together.
  int get unmet => histogram[0] ?? 0;

  /// The most often any feasible pair meets.
  int get maxDuplicates => meetingCounts.fold(0, (a, b) => a > b ? a : b);

  /// Total meetings of feasible pairs (constant for a given contest size).
  int get totalMeetings => meetingCounts.fold(0, (a, b) => a + b);

  /// Sum of squared meeting counts, the quantity the optimizer lowers.
  int get sumSquares => meetingCounts.fold(0, (a, b) => a + b * b);

  /// The mean meeting count of a feasible pair.
  double get mean => feasiblePairs == 0 ? 0 : totalMeetings / feasiblePairs;

  /// The matchup cost `J`: the sum over feasible pairs of `(c - mean)^2`.
  double get cost => feasiblePairs == 0
      ? 0
      : sumSquares - totalMeetings * totalMeetings / feasiblePairs;

  /// The lowest `J` any draw can reach: meeting counts are whole numbers, so
  /// with `f` the fractional part of the mean it is `pairs * f * (1 - f)`. A
  /// bound that is often out of reach.
  double get idealCost {
    final f = mean - mean.floorToDouble();
    return feasiblePairs * f * (1 - f);
  }

  /// Mean absolute deviation of the meeting counts from their mean.
  double get meanAbsoluteDeviation {
    if (feasiblePairs == 0) {
      return 0;
    }
    final m = mean;
    var total = unmet * m;
    for (final count in meetingCounts) {
      total += (count - m).abs();
    }
    return total / feasiblePairs;
  }

  /// Compares two draws: fewest never-met pairs, then the lowest maximum
  /// repeat, then the lowest sum of squares (`matrix-draw.md` section 3.3).
  /// Negative when this draw is better.
  int compareQuality(MatchupStats other) {
    final byUnmet = unmet.compareTo(other.unmet);
    if (byUnmet != 0) return byUnmet;
    final byMax = maxDuplicates.compareTo(other.maxDuplicates);
    if (byMax != 0) return byMax;
    return sumSquares.compareTo(other.sumSquares);
  }
}
