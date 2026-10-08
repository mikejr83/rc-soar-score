import 'package:equatable/equatable.dart';

import '../models/id.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_placeholder.dart';

/// One slot of the matrix with the score entered for it, if any.
class ScoreSlot extends Equatable {
  const ScoreSlot({required this.placeholder, this.officialScore});

  factory ScoreSlot.fromJson(Map<String, Object?> json) {
    final official = json['official_score'] as Map<String, Object?>?;
    return ScoreSlot(
      placeholder: ScorePlaceholder.fromJson(
        json['placeholder']! as Map<String, Object?>,
      ),
      officialScore: official == null ? null : OfficialScore.fromJson(official),
    );
  }

  final ScorePlaceholder placeholder;

  /// The current official score, null until one is entered.
  final OfficialScore? officialScore;

  Map<String, Object?> toJson() => {
    'placeholder': placeholder.toJson(),
    'official_score': officialScore?.toJson(),
  };

  @override
  List<Object?> get props => [placeholder, officialScore];
}

/// How far a round has been scored.
class RoundProgress extends Equatable {
  const RoundProgress({
    required this.roundId,
    required this.ordinal,
    required this.scored,
    required this.total,
  });

  factory RoundProgress.fromJson(Map<String, Object?> json) => RoundProgress(
    roundId: Id.parse(json['round_id']! as String),
    ordinal: json['ordinal']! as int,
    scored: json['scored']! as int,
    total: json['total']! as int,
  );

  final Id roundId;
  final int ordinal;

  /// The slots of the round that have a score.
  final int scored;

  /// The slots of the round.
  final int total;

  bool get isComplete => total > 0 && scored == total;
  bool get isStarted => scored > 0;

  Map<String, Object?> toJson() => {
    'round_id': roundId.value,
    'ordinal': ordinal,
    'scored': scored,
    'total': total,
  };

  @override
  List<Object?> get props => [roundId, ordinal, scored, total];
}

/// Every score slot of a contest's current matrix, with the progress of each
/// round.
class ContestScores extends Equatable {
  ContestScores({
    Iterable<ScoreSlot> slots = const [],
    Iterable<RoundProgress> rounds = const [],
  }) : slots = List.unmodifiable(slots),
       rounds = List.unmodifiable(rounds);

  factory ContestScores.fromJson(Map<String, Object?> json) => ContestScores(
    slots: [
      for (final slot in json['scores']! as List<Object?>)
        ScoreSlot.fromJson(slot! as Map<String, Object?>),
    ],
    rounds: [
      for (final round in json['rounds']! as List<Object?>)
        RoundProgress.fromJson(round! as Map<String, Object?>),
    ],
  );

  final List<ScoreSlot> slots;
  final List<RoundProgress> rounds;

  Map<String, Object?> toJson() => {
    'scores': [for (final slot in slots) slot.toJson()],
    'rounds': [for (final round in rounds) round.toJson()],
  };

  @override
  List<Object?> get props => [slots, rounds];
}
