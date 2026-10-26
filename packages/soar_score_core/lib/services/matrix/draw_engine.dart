import 'dart:math' as math;

import '../../enums/lane_mode.dart';
import 'basic_draw.dart';
import 'draw_fairness.dart';
import 'draw_job.dart';
import 'draw_optimizer.dart';
import 'lane_stats.dart';
import 'matchup_stats.dart';
import 'seeded_random.dart';

/// A finished draw: the groups, the seed that made them, and how fair they
/// are.
class DrawResult {
  const DrawResult({
    required this.rounds,
    required this.seed,
    required this.fairness,
  });

  /// `rounds[round][group]` lists the slots of that group.
  final List<List<List<DrawSlot>>> rounds;

  /// The seed of the winning run. Drawing again with this seed and one run
  /// reproduces [rounds].
  final int seed;

  /// The fairness report stored with the revision.
  final Map<String, Object?> fairness;
}

/// Draws a matrix as `matrix-draw.md` section 4 describes: build a valid draw
/// round by round, improve it across all rounds, and do so for several seeds,
/// keeping the fairest result.
///
/// Runs are compared by fewest never-met pairs, then the lowest maximum
/// repeat, then the lowest total cost `J` (the matchup penalty plus 0.15 times
/// the lane penalty, `matrix-draw.md` section 3.3). The winning run's seed is
/// returned so the draw can be reproduced.
class DrawEngine {
  const DrawEngine();

  /// The version recorded on matrices this engine draws.
  static const String algorithmVersion = 'optimized-1';

  /// How many seeds are tried by default, and the most allowed.
  static const int defaultSeedCount = 3;
  static const int maxSeedCount = 20;

  /// How many random draws set the 0% mark of the fairness score, and the
  /// seed they use. Both are fixed so a matrix always gets the same score.
  static const int _randomSamples = 20;

  /// The weight of the lane penalty in the total cost `J`.
  static const double laneWeight = 0.15;
  static const int _randomSeed = 0x5EED;

  /// [rounds] is how many rounds to draw. [history] holds the rounds before
  /// them, kept as they are: the draw continues them, so who has already met
  /// counts, and the fairness report covers [history] and the new rounds
  /// together.
  ///
  /// [onProgress] hears how far the run has come, from 0 to 99 percent, as
  /// each cooling step of each seed starts. It only watches: the draw is the
  /// same with or without it.
  ///
  /// Throws an [ArgumentError] when the settings cannot be met, as
  /// [BasicDraw.generate] does, and for a [seedCount] outside
  /// 1 to [maxSeedCount].
  DrawResult generate({
    required List<DrawPilot> pilots,
    required int rounds,
    required int groupsPerRound,
    required bool teamProtection,
    required LaneMode laneMode,
    required int seed,
    int seedCount = defaultSeedCount,
    int attemptsPerRound = BasicDraw.defaultAttemptsPerRound,
    int iterationsPerPlacement = DrawOptimizer.defaultIterationsPerPlacement,
    List<List<List<DrawSlot>>> history = const [],
    void Function(DrawProgress progress)? onProgress,
  }) {
    if (seedCount < 1 || seedCount > maxSeedCount) {
      throw ArgumentError.value(
        seedCount,
        'seedCount',
        'must be between 1 and $maxSeedCount',
      );
    }
    // The first run uses [seed] itself, so a winning seed drawn again with
    // one run gives the same matrix; the others come from its stream.
    final stream = SeededRandom(seed);
    final seeds = [
      seed,
      for (var i = 1; i < seedCount; i++) stream.nextUint32(),
    ];

    List<List<List<DrawSlot>>>? best;
    MatchupStats? bestStats;
    LaneStats? bestLanes;
    var bestCost = 0.0;
    var bestSeed = seed;
    for (var seedIndex = 0; seedIndex < seeds.length; seedIndex++) {
      final candidate = seeds[seedIndex];
      final random = SeededRandom(candidate);
      final built = const BasicDraw().generate(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: teamProtection,
        laneMode: laneMode,
        random: random,
        attemptsPerRound: attemptsPerRound,
        history: history,
      );
      final improved = const DrawOptimizer().improve(
        pilots: pilots,
        start: built,
        teamProtection: teamProtection,
        laneMode: laneMode,
        random: random,
        iterationsPerPlacement: iterationsPerPlacement,
        history: history,
        onLevel: onProgress == null
            ? null
            : (level) => onProgress(
                DrawProgress(
                  percent:
                      (100 * (seedIndex * DrawOptimizer.levels + level)) ~/
                      (seeds.length * DrawOptimizer.levels + 1),
                  seed: seedIndex + 1,
                  seedCount: seeds.length,
                ),
              ),
      );
      final all = [...history, ...improved];
      final stats = MatchupStats.of(all, teamProtection: teamProtection);
      final lanes = LaneStats.of(all);
      final cost = _cost(stats, lanes);
      if (bestStats == null || _isBetter(stats, cost, bestStats, bestCost)) {
        best = improved;
        bestStats = stats;
        bestLanes = lanes;
        bestCost = cost;
        bestSeed = candidate;
      }
    }

    final fairness = drawFairness([
      ...history,
      ...best!,
    ], teamProtection: teamProtection);
    fairness['fairness_score'] = _score(
      bestStats!,
      bestLanes,
      laneMode: laneMode,
      pilots: pilots,
      rounds: rounds,
      groupsPerRound: groupsPerRound,
      teamProtection: teamProtection,
      fairness: fairness,
      history: history,
    );
    return DrawResult(rounds: best, seed: bestSeed, fairness: fairness);
  }

  /// The total cost `J`: the matchup penalty plus [laneWeight] times the
  /// lane penalty (zero without lanes).
  double _cost(MatchupStats stats, LaneStats? lanes) =>
      stats.cost + laneWeight * (lanes?.cost ?? 0);

  /// Fewest never-met pairs, then the lowest maximum repeat, then the lowest
  /// total cost.
  bool _isBetter(
    MatchupStats stats,
    double cost,
    MatchupStats other,
    double otherCost,
  ) {
    if (stats.unmet != other.unmet) return stats.unmet < other.unmet;
    if (stats.maxDuplicates != other.maxDuplicates) {
      return stats.maxDuplicates < other.maxDuplicates;
    }
    return cost < otherCost;
  }

  /// 100% when the draw reaches the best total cost any draw could, 0% when
  /// it is no better than the average random draw of the same contest
  /// (`matrix-draw.md` section 7.2), as a percentage to one decimal.
  /// Adds the costs it used to [fairness].
  double _score(
    MatchupStats stats,
    LaneStats? lanes, {
    required LaneMode laneMode,
    required List<DrawPilot> pilots,
    required int rounds,
    required int groupsPerRound,
    required bool teamProtection,
    required Map<String, Object?> fairness,
    required List<List<List<DrawSlot>>> history,
  }) {
    final random = SeededRandom(_randomSeed);
    var total = 0.0;
    for (var i = 0; i < _randomSamples; i++) {
      final sample = const BasicDraw().generate(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: teamProtection,
        laneMode: laneMode,
        random: random,
        spreadMeetings: false,
        history: history,
      );
      final all = [...history, ...sample];
      total += _cost(
        MatchupStats.of(all, teamProtection: teamProtection),
        LaneStats.of(all),
      );
    }
    final worst = total / _randomSamples;
    final cost = _cost(stats, lanes);
    final ideal = stats.idealCost + laneWeight * (lanes?.idealCost ?? 0);
    fairness['matchup_cost'] = stats.cost;
    fairness['cost'] = cost;
    fairness['cost_ideal'] = ideal;
    fairness['cost_random_average'] = worst;
    if (worst <= ideal) {
      return 100;
    }
    final share = 1 - (cost - ideal) / (worst - ideal);
    return (math.max(0, math.min(1, share)) * 1000).round() / 10;
  }
}
