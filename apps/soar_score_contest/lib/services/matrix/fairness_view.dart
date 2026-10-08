/// How good a draw is, in words.
enum FairnessTier {
  poor('Poor draw'),
  average('Average draw'),
  good('Good draw');

  const FairnessTier(this.label);

  final String label;
}

/// The fairness report stored with a matrix revision, read for display.
class FairnessView {
  const FairnessView({
    required this.score,
    required this.unmet,
    required this.maxRepeats,
    required this.meanAbsoluteDeviation,
    required this.histogram,
    required this.feasiblePairs,
    this.laneUniformity,
  });

  /// Reads [summary]; every figure is optional because a draw may not have
  /// recorded it.
  factory FairnessView.of(Map<String, Object?>? summary) {
    final raw = summary?['matchup_histogram'];
    return FairnessView(
      score: (summary?['fairness_score'] as num?)?.toDouble(),
      unmet: (summary?['unmet_opponent_count'] as num?)?.toInt(),
      maxRepeats: (summary?['max_duplicate_matchups'] as num?)?.toInt(),
      meanAbsoluteDeviation: (summary?['mean_absolute_deviation'] as num?)
          ?.toDouble(),
      feasiblePairs: (summary?['feasible_pairs'] as num?)?.toInt(),
      laneUniformity: (summary?['lane_uniformity_index'] as num?)?.toDouble(),
      histogram: raw is Map
          ? {
              for (final entry in raw.entries)
                int.parse('${entry.key}'): (entry.value as num).toInt(),
            }
          : const {},
    );
  }

  /// 0 to 100: 0 is a random draw, 100 the best possible. A
  /// draw worse than random is floored to 0 by the engine.
  final double? score;
  final int? unmet;
  final int? maxRepeats;
  final double? meanAbsoluteDeviation;
  final int? feasiblePairs;

  /// The spread of lane use; 0 is perfectly even. `null` without lanes.
  final double? laneUniformity;

  /// Pairs by number of meetings.
  final Map<int, int> histogram;

  FairnessTier? get tier {
    final score = this.score;
    if (score == null) {
      return null;
    }
    return score < 25
        ? FairnessTier.poor
        : score < 75
        ? FairnessTier.average
        : FairnessTier.good;
  }

  /// "92%", or "92.4%" when the score has a decimal.
  String get scoreText {
    final score = this.score;
    if (score == null) {
      return '–';
    }
    return score == score.roundToDouble()
        ? '${score.round()}%'
        : '${score.toStringAsFixed(1)}%';
  }

  /// Histogram rows: never, once, twice and 3 or more meetings.
  List<(String, int)> get bars {
    int sum(bool Function(int) test) => histogram.entries
        .where((entry) => test(entry.key))
        .fold(0, (total, entry) => total + entry.value);
    return [
      ('Never', sum((k) => k == 0)),
      ('Once', sum((k) => k == 1)),
      ('Twice', sum((k) => k == 2)),
      ('3+ times', sum((k) => k >= 3)),
    ];
  }
}
