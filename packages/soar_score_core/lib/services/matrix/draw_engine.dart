import 'dart:math' as math;

import '../../enums/lane_mode.dart';
import 'basic_draw.dart';
import 'draw_fairness.dart';
import 'draw_optimizer.dart';
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
/// repeat, then the lowest sum of squared meeting counts. The winning run's
/// seed is returned so the draw can be reproduced.
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
  static const int _randomSeed = 0x5EED;

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
    var bestSeed = seed;
    for (final candidate in seeds) {
      final random = SeededRandom(candidate);
      final built = const BasicDraw().generate(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: teamProtection,
        laneMode: laneMode,
        random: random,
        attemptsPerRound: attemptsPerRound,
      );
      final improved = const DrawOptimizer().improve(
        pilots: pilots,
        start: built,
        teamProtection: teamProtection,
        laneMode: laneMode,
        random: random,
        iterationsPerPlacement: iterationsPerPlacement,
      );
      final stats = MatchupStats.of(improved, teamProtection: teamProtection);
      if (bestStats == null || stats.compareQuality(bestStats) < 0) {
        best = improved;
        bestStats = stats;
        bestSeed = candidate;
      }
    }

    final fairness = drawFairness(best!, teamProtection: teamProtection);
    fairness['fairness_score'] = _score(
      bestStats!,
      pilots: pilots,
      rounds: rounds,
      groupsPerRound: groupsPerRound,
      teamProtection: teamProtection,
      fairness: fairness,
    );
    return DrawResult(rounds: best, seed: bestSeed, fairness: fairness);
  }

  /// 100% when the draw reaches the best cost any draw could, 0% when it is
  /// no better than the average random draw of the same contest (`matrix-draw.md`
  /// section 7.2), as a percentage to one decimal.
  double _score(
    MatchupStats stats, {
    required List<DrawPilot> pilots,
    required int rounds,
    required int groupsPerRound,
    required bool teamProtection,
    required Map<String, Object?> fairness,
  }) {
    final random = SeededRandom(_randomSeed);
    var total = 0.0;
    for (var i = 0; i < _randomSamples; i++) {
      final sample = const BasicDraw().generate(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: teamProtection,
        laneMode: LaneMode.none,
        random: random,
        spreadMeetings: false,
      );
      total += MatchupStats.of(sample, teamProtection: teamProtection).cost;
    }
    final worst = total / _randomSamples;
    final ideal = stats.idealCost;
    fairness['matchup_cost'] = stats.cost;
    fairness['matchup_cost_ideal'] = ideal;
    fairness['matchup_cost_random_average'] = worst;
    if (worst <= ideal) {
      return 100;
    }
    final share = 1 - (stats.cost - ideal) / (worst - ideal);
    return (math.max(0, math.min(1, share)) * 1000).round() / 10;
  }
}
