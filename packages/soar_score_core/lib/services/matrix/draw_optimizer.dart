import '../../enums/lane_mode.dart';
import 'acceptance_table.dart';
import 'basic_draw.dart';
import 'lane_balancer.dart';
import 'seeded_random.dart';

/// Improves a valid draw across all of its rounds: conflict-directed
/// simulated annealing on who meets whom, then lane balancing
/// (`matrix-draw.md` section 4).
///
/// A move swaps two pilots of two groups in one round. It is refused when it
/// would put two teammates together under team protection; otherwise it is
/// accepted when it lowers the cost, or, with a probability that falls as the
/// run cools, when it raises it. Group sizes never change, so the draw stays
/// valid.
///
/// The cost is the sum of squared meeting counts (the matchup cost `J`
/// differs from it by a constant) plus [unmetWeight] for each pair that
/// never meets. Everything is whole numbers, and the acceptance test comes
/// from [AcceptanceTable], so the same inputs give the same draw on every
/// platform.
class DrawOptimizer {
  const DrawOptimizer();

  /// Moves tried per pilot placement (pilots times rounds) by default. The
  /// research benchmark needed about 340 to 625 per placement to match
  /// GliderScore on team contests.
  static const int defaultIterationsPerPlacement = 400;

  /// What a pair that never meets costs on top of the squared counts.
  static const int defaultUnmetWeight = 4;

  /// Cooling steps. The temperature falls by [_ratio] 65,536ths at each, from
  /// [_startTemperature256] to about 1/256, which is the floor: the run
  /// always uses its whole budget.
  static const int levels = 100;
  static const int _ratio = 61582;
  static const int _startTemperature256 = 512; // T0 = 2.0

  /// [start] improved. [pilots] lists every pilot of [start] once. [history]
  /// holds the rounds before [start], which the improved rounds continue;
  /// they are not changed, but their meetings count. [onLevel] hears each
  /// cooling step as it starts, 0 up to [levels]; it only watches, so the
  /// draw is the same with or without it.
  List<List<List<DrawSlot>>> improve({
    required List<DrawPilot> pilots,
    required List<List<List<DrawSlot>>> start,
    required bool teamProtection,
    required LaneMode laneMode,
    required SeededRandom random,
    int iterationsPerPlacement = defaultIterationsPerPlacement,
    int unmetWeight = defaultUnmetWeight,
    bool allowBackToBack = true,
    List<List<List<DrawSlot>>> history = const [],
    void Function(int level)? onLevel,
  }) {
    final n = pilots.length;
    final roundCount = start.length;
    final index = {for (var i = 0; i < n; i++) pilots[i].participationId: i};
    final teams = <Object, int>{};
    final team = [
      for (final pilot in pilots)
        pilot.teamId == null
            ? -1
            : teams.putIfAbsent(pilot.teamId!, () => teams.length),
    ];
    final groups = [
      for (final round in start)
        [
          for (final group in round)
            [for (final slot in group) index[slot.pilot.participationId]!],
        ],
    ];
    final lanes = [for (final round in start) _laneTable(round, index, n)];
    final prior = [
      for (final round in history)
        [
          for (final group in round)
            [
              for (final slot in group)
                if (index[slot.pilot.participationId] != null)
                  index[slot.pilot.participationId]!,
            ],
        ],
    ];

    if (groups.isNotEmpty && groups.first.length > 1) {
      _anneal(
        n: n,
        groups: groups,
        prior: prior,
        lanes: lanes,
        team: teamProtection ? team : null,
        backToBack: !allowBackToBack,
        random: random,
        iterations: iterationsPerPlacement * n * roundCount,
        unmetWeight: unmetWeight,
        onLevel: onLevel,
      );
    }
    if (laneMode == LaneMode.random) {
      LaneBalancer().balance(
        n: n,
        groups: groups,
        lanes: lanes,
        random: random,
        iterationsPerPlacement: 100,
      );
    }
    return [
      for (var r = 0; r < roundCount; r++)
        [
          for (final group in groups[r])
            [
              for (final p in group)
                DrawSlot(
                  pilots[p],
                  laneMode == LaneMode.random ? lanes[r][p] : null,
                ),
            ],
        ],
    ];
  }

  /// The lane of each pilot in one round (0 when there is none).
  List<int> _laneTable(
    List<List<DrawSlot>> round,
    Map<Object, int> index,
    int n,
  ) {
    final lanes = List<int>.filled(n, 0);
    for (final group in round) {
      for (final slot in group) {
        lanes[index[slot.pilot.participationId]!] = slot.lane ?? 0;
      }
    }
    return lanes;
  }

  void _anneal({
    required int n,
    required List<List<List<int>>> groups,
    required List<List<List<int>>> prior,
    required List<List<int>> lanes,
    required List<int>? team,
    required bool backToBack,
    required SeededRandom random,
    required int iterations,
    required int unmetWeight,
    required void Function(int level)? onLevel,
  }) {
    final roundCount = groups.length;
    final groupCount = groups.first.length;
    final meet = List<int>.filled(n * n, 0);
    for (final round in [...prior, ...groups]) {
      for (final group in round) {
        for (var i = 0; i < group.length; i++) {
          for (var j = i + 1; j < group.length; j++) {
            meet[group[i] * n + group[j]]++;
            meet[group[j] * n + group[i]]++;
          }
        }
      }
    }

    final table = AcceptanceTable.instance;
    final perLevel = iterations ~/ levels > 0 ? iterations ~/ levels : 1;
    var temperature = _startTemperature256;
    for (var i = 0; i < iterations; i++) {
      if (onLevel != null && i % perLevel == 0) {
        onLevel(i ~/ perLevel < levels ? i ~/ perLevel : levels);
      }
      if (i > 0 && i % perLevel == 0 && temperature > 1) {
        temperature = (temperature * _ratio + 32768) ~/ 65536;
        if (temperature < 1) temperature = 1;
      }
      final r = random.nextInt(roundCount);
      final a = random.nextInt(groupCount);
      var b = random.nextInt(groupCount - 1);
      if (b >= a) b++;
      final ga = groups[r][a];
      final gb = groups[r][b];

      // Half of the moves take the pilot with the most meetings in its
      // group; the other half a random one.
      var xi = random.nextInt(ga.length);
      if (i.isEven) {
        var worst = -1;
        for (var k = 0; k < ga.length; k++) {
          var total = 0;
          for (final q in ga) {
            total += meet[ga[k] * n + q];
          }
          if (total > worst) {
            worst = total;
            xi = k;
          }
        }
      }
      final yi = random.nextInt(gb.length);
      final x = ga[xi];
      final y = gb[yi];

      if (team != null) {
        if (_clashes(team, x, gb, y) || _clashes(team, y, ga, x)) {
          continue;
        }
      }

      if (backToBack &&
          (_opensAfterItsLast(groups, prior, r, b, x) ||
              _opensAfterItsLast(groups, prior, r, a, y) ||
              _closesBeforeItsFirst(groups, r, b, x) ||
              _closesBeforeItsFirst(groups, r, a, y))) {
        continue;
      }

      var delta = 0;
      for (final q in ga) {
        if (q == x) continue;
        final lost = meet[x * n + q];
        delta += 1 - 2 * lost;
        if (lost == 1) delta += unmetWeight;
        final gained = meet[y * n + q];
        delta += 1 + 2 * gained;
        if (gained == 0) delta -= unmetWeight;
      }
      for (final q in gb) {
        if (q == y) continue;
        final lost = meet[y * n + q];
        delta += 1 - 2 * lost;
        if (lost == 1) delta += unmetWeight;
        final gained = meet[x * n + q];
        delta += 1 + 2 * gained;
        if (gained == 0) delta -= unmetWeight;
      }

      final chance = table.probability(delta, temperature);
      if (chance < 65536 && random.nextUint32() ~/ 65536 >= chance) {
        continue;
      }

      for (final q in ga) {
        if (q == x) continue;
        meet[x * n + q]--;
        meet[q * n + x]--;
        meet[y * n + q]++;
        meet[q * n + y]++;
      }
      for (final q in gb) {
        if (q == y) continue;
        meet[y * n + q]--;
        meet[q * n + y]--;
        meet[x * n + q]++;
        meet[q * n + x]++;
      }
      ga[xi] = y;
      gb[yi] = x;
      final lane = lanes[r][x];
      lanes[r][x] = lanes[r][y];
      lanes[r][y] = lane;
    }
  }

  /// Whether moving [pilot] into group [to] of round [r] puts it in the
  /// first group right after a round where it flew in the last one.
  bool _opensAfterItsLast(
    List<List<List<int>>> groups,
    List<List<List<int>>> prior,
    int r,
    int to,
    int pilot,
  ) {
    if (to != 0) return false;
    final before = r > 0 ? groups[r - 1] : (prior.isEmpty ? null : prior.last);
    if (before == null || before.isEmpty) return false;
    return before.last.contains(pilot);
  }

  /// Whether moving [pilot] into group [to] of round [r], when that is the
  /// last group, puts it right before a round where it flies in the first.
  bool _closesBeforeItsFirst(
    List<List<List<int>>> groups,
    int r,
    int to,
    int pilot,
  ) {
    if (r + 1 >= groups.length || to != groups[r].length - 1) return false;
    return groups[r + 1].first.contains(pilot);
  }

  /// Whether [pilot] has a teammate in [group], not counting [leaving].
  bool _clashes(List<int> team, int pilot, List<int> group, int leaving) {
    final mine = team[pilot];
    if (mine < 0) return false;
    for (final q in group) {
      if (q != leaving && team[q] == mine) return true;
    }
    return false;
  }
}
