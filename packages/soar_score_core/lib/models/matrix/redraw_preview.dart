import 'package:equatable/equatable.dart';

/// The answer of a redraw that was drawn but not stored: how fair the
/// candidate is, and which seed would draw it.
///
/// [candidateFairness] is the fairness report the candidate draw would store
/// (the kept rounds and the new tail together), and [currentFairness] the
/// report the current matrix revision already has. [better] says whether the
/// candidate wins on it in the draw's comparison order. Not an entity.
class RedrawPreview extends Equatable {
  RedrawPreview({
    required this.seed,
    required Map<String, Object?> candidateFairness,
    Map<String, Object?>? currentFairness,
    bool? better,
  }) : candidateFairness = Map.unmodifiable(candidateFairness),
       currentFairness = currentFairness == null
           ? null
           : Map.unmodifiable(currentFairness),
       better =
           better ??
           (currentFairness != null &&
               _isFairer(candidateFairness, currentFairness));

  factory RedrawPreview.fromJson(Map<String, Object?> json) {
    Map<String, Object?>? read(String key) {
      final value = json[key];
      if (value == null) return null;
      return {
        for (final entry in (value as Map).entries)
          entry.key as String: entry.value,
      };
    }

    return RedrawPreview(
      seed: (json['seed'] as num).toInt(),
      candidateFairness: read('candidate_fairness')!,
      currentFairness: read('current_fairness'),
      better: json['better'] as bool,
    );
  }

  /// The seed of the winning run of the candidate draw; drawing with it and
  /// one seed reproduces the candidate.
  final int seed;

  /// The fairness report the candidate redraw would store.
  final Map<String, Object?> candidateFairness;

  /// The fairness report the current matrix revision already has; `null`
  /// when the revision records no fairness.
  final Map<String, Object?>? currentFairness;

  /// Whether the candidate beats the current matrix on the draw's comparison
  /// order. When [currentFairness] is missing there is nothing to beat, so it
  /// is false.
  final bool better;

  /// Whether [candidate] is fairer than [current] in the draw's comparison
  /// order: fewest never-met pairs, then the lowest maximum repeat, then the
  /// lowest total cost `J` (`matrix-draw.md` section 3.3).
  static bool _isFairer(
    Map<String, Object?> candidate,
    Map<String, Object?> current,
  ) {
    final unmet = _int(candidate['unmet_opponent_count']);
    final otherUnmet = _int(current['unmet_opponent_count']);
    if (unmet != otherUnmet) return unmet < otherUnmet;
    final max = _int(candidate['max_duplicate_matchups']);
    final otherMax = _int(current['max_duplicate_matchups']);
    if (max != otherMax) return max < otherMax;
    final cost = (candidate['cost'] as num?)?.toDouble();
    final otherCost = (current['cost'] as num?)?.toDouble();
    if (cost == null || otherCost == null) return false;
    return cost < otherCost;
  }

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  Map<String, Object?> toJson() => {
    'seed': seed,
    'candidate_fairness': candidateFairness,
    'current_fairness': currentFairness,
    'better': better,
  };

  @override
  List<Object?> get props => [seed, candidateFairness, currentFairness, better];
}
