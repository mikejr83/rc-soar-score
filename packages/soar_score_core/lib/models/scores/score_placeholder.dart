import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/score_placeholder_state.dart';
import '../../enums/selection_origin.dart';
import '../id.dart';
import '../shared/shared.dart';
import 'official_score.dart';

part 'score_placeholder.g.dart';

/// The reserved slot for one assignment's score.
///
/// [state] summarizes the workflow; the facts live in attempts, review
/// requests and official scores. See
/// `plan/data-model/entities/score_placeholder.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ScorePlaceholder extends Equatable implements Synchronizable {
  ScorePlaceholder({
    required this.id,
    required this.contestId,
    required this.contestParticipationId,
    required this.assignmentId,
    this.state = ScorePlaceholderState.notEntered,
    this.scoreRevision = 0,
    this.currentAttemptId,
    this.lockedBy,
    DateTime? lockedAt,
    this.reviewClosedScoreRevision,
    this.revision = 0,
  }) : lockedAt = lockedAt?.toUtc() {
    requireNonNegative(scoreRevision, 'scoreRevision');
    if ((lockedBy == null) != (lockedAt == null)) {
      throw ArgumentError('locked_by and locked_at are set together');
    }
    requireNonNegative(revision, 'revision');
    if (reviewClosedScoreRevision != null) {
      requirePositive(reviewClosedScoreRevision!, 'reviewClosedScoreRevision');
    }
  }

  factory ScorePlaceholder.fromJson(Map<String, Object?> json) =>
      _$ScorePlaceholderFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id contestParticipationId;

  /// The assignment this scores; never changes.
  final Id assignmentId;

  final ScorePlaceholderState state;

  /// Counts accepted score mutations: attempts accepted and official
  /// versions created.
  final int scoreRevision;

  /// The attempt whose values are the slot's current submission: the
  /// authoritative frontier of accepted attempts, advanced in the same
  /// transaction as [scoreRevision]. Null while nothing is entered. Never
  /// inferred from attempt id order.
  final Id? currentAttemptId;

  /// Set when this score is locked on its own.
  final Id? lockedBy;
  final DateTime? lockedAt;

  /// The [scoreRevision] for which a director explicitly closed review
  /// without a new official version, for example by confirming an
  /// automatically accepted score. Null when no such decision was made. It
  /// applies only while it equals the current [scoreRevision]: any newer
  /// score starts open again.
  final int? reviewClosedScoreRevision;

  @override
  final int revision;

  bool get isLocked => lockedAt != null;

  /// True when a director's explicit decision closed review for the current
  /// score by [reviewClosedScoreRevision]. Whether the official version
  /// itself closes review depends on its origin; use [isReviewClosed].
  bool get hasReviewClosure =>
      reviewClosedScoreRevision != null &&
      reviewClosedScoreRevision == scoreRevision;

  /// Whether a participant can no longer ask for a review of the current
  /// score because of a director's explicit decision: [current] is the
  /// placeholder's current official version, if any.
  ///
  /// Official status alone does not close review. A score the contest
  /// accepted automatically stays reviewable until it is locked (see
  /// [isLocked], which callers check separately) or a director decides it.
  /// A manual or review-decision version is itself the decision.
  bool isReviewClosed(OfficialScore? current) {
    if (current == null || current.scoreRevision != scoreRevision) {
      return false;
    }
    return current.selectionOrigin != SelectionOrigin.automatic ||
        hasReviewClosure;
  }

  @override
  String get entityType => 'ScorePlaceholder';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ScorePlaceholderToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    contestParticipationId,
    assignmentId,
    state,
    scoreRevision,
    currentAttemptId,
    lockedBy,
    lockedAt,
    reviewClosedScoreRevision,
    revision,
  ];
}
