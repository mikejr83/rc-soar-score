import '../models/contest/contest.dart';
import '../models/matrix/matrix_draw.dart';
import '../models/participants/contest_participation.dart';
import '../models/scores/score_placeholder.dart';

/// A draw together with everything that must change in the same transaction
/// when it is finalized: the score placeholders of its `Original`
/// assignments, the participant numbers it allocated, and the contest, which
/// becomes `Ready`.
class FinalizedDraw {
  FinalizedDraw({
    required this.draw,
    required Iterable<ScorePlaceholder> placeholders,
    required Iterable<ContestParticipation> numberedParticipations,
    required this.contest,
  }) : placeholders = List.unmodifiable(placeholders),
       numberedParticipations = List.unmodifiable(numberedParticipations);

  /// The finalized revision with its rounds, groups and assignments.
  final MatrixDraw draw;

  /// One placeholder for each `Original` assignment of [draw].
  final List<ScorePlaceholder> placeholders;

  /// The participations that received a participant number, as they are to be
  /// stored.
  final List<ContestParticipation> numberedParticipations;

  /// The contest as it is to be stored (`Ready`).
  final Contest contest;
}
