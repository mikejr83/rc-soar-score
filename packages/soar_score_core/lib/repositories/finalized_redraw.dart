import '../models/matrix/matrix_draw.dart';
import '../models/matrix/round.dart';
import '../models/participants/contest_participation.dart';
import '../models/scores/score_placeholder.dart';

/// A redraw (rounds added to the matrix, or the unscored tail of it drawn
/// again) with everything that must change in the same transaction when it is
/// finalized: the score placeholders of its `Original` assignments, the
/// participant numbers it allocated, and the rounds it replaces.
class FinalizedRedraw {
  FinalizedRedraw({
    required this.draw,
    required Iterable<ScorePlaceholder> placeholders,
    required Iterable<ContestParticipation> numberedParticipations,
    required Iterable<Round> replacedRounds,
  }) : placeholders = List.unmodifiable(placeholders),
       numberedParticipations = List.unmodifiable(numberedParticipations),
       replacedRounds = List.unmodifiable(replacedRounds);

  /// The finalized revision with its new rounds, groups and assignments.
  final MatrixDraw draw;

  /// One placeholder for each `Original` assignment of [draw].
  final List<ScorePlaceholder> placeholders;

  /// The participations that received a participant number, as they are to be
  /// stored.
  final List<ContestParticipation> numberedParticipations;

  /// The rounds the redraw takes over from, as they are to be stored: each
  /// either superseded by its new round or cancelled.
  final List<Round> replacedRounds;
}
