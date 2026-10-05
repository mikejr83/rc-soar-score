import 'package:equatable/equatable.dart';

/// A pilot's contest total as of a round, with the dropped-round decision.
class ContestTotal extends Equatable {
  ContestTotal({
    required this.pilotId,
    required this.asOfRound,
    required this.rawTotal,
    required List<int> droppedRounds,
    required this.skippedDrops,
    required this.penaltyTotal,
    required this.overallScore,
    required this.isPreliminary,
  }) : droppedRounds = List.unmodifiable(droppedRounds);

  final String pilotId;
  final int asOfRound;

  /// The sum of every round score up to the round, before drops and
  /// penalties. Shown as "Raw Score".
  final double rawTotal;

  /// The dropped round ordinals, ascending. Never a non-droppable zero.
  final List<int> droppedRounds;

  /// Drops the options called for that could not be made because no eligible
  /// round was left, as when every remaining round is a non-droppable zero.
  final int skippedDrops;

  /// The cumulative penalties on every flight up to the round. A dropped round
  /// never removes its penalty.
  final double penaltyTotal;

  /// The kept round scores less the penalty total. Shown as "Score".
  final double overallScore;

  /// True while a round up to the as-of round has no score or an open review.
  final bool isPreliminary;

  @override
  List<Object?> get props => [
    pilotId,
    asOfRound,
    rawTotal,
    droppedRounds,
    skippedDrops,
    penaltyTotal,
    overallScore,
    isPreliminary,
  ];
}
