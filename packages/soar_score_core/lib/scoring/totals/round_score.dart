import 'package:equatable/equatable.dart';

/// A pilot's selected score for one round, as input to the contest total.
class RoundScore extends Equatable {
  RoundScore({
    required this.round,
    required this.groupScore,
    required this.rawScore,
    this.nonDroppable = false,
    this.cumulativePenalty = 0,
    this.underReview = false,
  }) {
    if (round < 1) {
      throw ArgumentError.value(round, 'round', 'must be at least 1');
    }
    if (!groupScore.isFinite || groupScore < 0) {
      throw ArgumentError.value(
        groupScore,
        'groupScore',
        'must not be negative',
      );
    }
    if (!rawScore.isFinite || rawScore < 0) {
      throw ArgumentError.value(rawScore, 'rawScore', 'must not be negative');
    }
    if (!cumulativePenalty.isFinite || cumulativePenalty < 0) {
      throw ArgumentError.value(
        cumulativePenalty,
        'cumulativePenalty',
        'must not be negative',
      );
    }
  }

  /// The round ordinal, starting at 1.
  final int round;

  /// The group score of the selected flight, already rounded.
  final double groupScore;

  /// The discipline raw score of the selected flight, before the group score.
  /// Its total across rounds is the second tie-breaker.
  final double rawScore;

  /// A zero that may never be dropped, such as an F5J motor restart under
  /// `Non-Droppable 0`.
  final bool nonDroppable;

  /// The sum of the cumulative penalties on every flight the pilot has on a
  /// current assignment in this round, whether or not that flight is the
  /// selected one. An absent penalty is zero.
  final double cumulativePenalty;

  /// An open review makes the total preliminary.
  final bool underReview;

  @override
  List<Object?> get props => [
    round,
    groupScore,
    rawScore,
    nonDroppable,
    cumulativePenalty,
    underReview,
  ];
}
