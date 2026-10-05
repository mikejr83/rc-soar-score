import 'package:equatable/equatable.dart';

import 'round_score.dart';

/// Everything the contest total needs about one pilot.
class PilotRounds extends Equatable {
  PilotRounds({
    required this.pilotId,
    required List<RoundScore> scores,
    this.retiredAtRound,
  }) : scores = List.unmodifiable(scores) {
    if (retiredAtRound != null && retiredAtRound! < 1) {
      throw ArgumentError.value(retiredAtRound, 'retiredAtRound');
    }
    final rounds = this.scores.map((s) => s.round).toSet();
    if (rounds.length != this.scores.length) {
      throw ArgumentError.value(scores, 'scores', 'a round appears twice');
    }
  }

  final String pilotId;
  final List<RoundScore> scores;

  /// The first round the pilot did not fly because they retired. Later rounds
  /// count as zeros with no record. Null when the pilot has not retired.
  final int? retiredAtRound;

  @override
  List<Object?> get props => [pilotId, scores, retiredAtRound];
}
