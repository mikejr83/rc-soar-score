import 'seeded_random.dart';

/// Evens out how often each pilot flies from each lane (`matrix-draw.md`
/// section 3.3, the lane penalty), without changing who flies in which group.
///
/// Lanes run from 1 to the largest group size. A move puts a pilot on
/// another lane of their group, swapping with whoever has it, and is kept
/// when it does not raise the penalty `sum((count - R / L)^2)`; the penalty
/// is scaled by `L` so everything stays in whole numbers.
class LaneBalancer {
  void balance({
    required int n,
    required List<List<List<int>>> groups,
    required List<List<int>> lanes,
    required SeededRandom random,
    required int iterationsPerPlacement,
  }) {
    final roundCount = groups.length;
    var laneCount = 0;
    for (final round in groups) {
      for (final group in round) {
        if (group.length > laneCount) laneCount = group.length;
      }
    }
    if (laneCount < 2) return;

    final used = [for (var p = 0; p < n; p++) List<int>.filled(laneCount, 0)];
    for (var r = 0; r < roundCount; r++) {
      for (final group in groups[r]) {
        for (final p in group) {
          used[p][lanes[r][p] - 1]++;
        }
      }
    }

    // The penalty of `count` flights from one lane, times L squared.
    int penalty(int count) {
      final d = count * laneCount - roundCount;
      return d * d;
    }

    // What moving pilot [p] from lane [from] to lane [to] adds.
    int change(int p, int from, int to) =>
        penalty(used[p][to] + 1) -
        penalty(used[p][to]) +
        penalty(used[p][from] - 1) -
        penalty(used[p][from]);

    final iterations = iterationsPerPlacement * n * roundCount;
    for (var i = 0; i < iterations; i++) {
      final r = random.nextInt(roundCount);
      final group = groups[r][random.nextInt(groups[r].length)];
      final x = group[random.nextInt(group.length)];
      final from = lanes[r][x] - 1;
      var to = random.nextInt(laneCount - 1);
      if (to >= from) to++;

      int? other;
      for (final q in group) {
        if (lanes[r][q] - 1 == to) other = q;
      }
      var delta = change(x, from, to);
      if (other != null) {
        delta += change(other, to, from);
      }
      if (delta > 0) continue;

      used[x][from]--;
      used[x][to]++;
      lanes[r][x] = to + 1;
      if (other != null) {
        used[other][to]--;
        used[other][from]++;
        lanes[r][other] = from + 1;
      }
    }
  }
}
