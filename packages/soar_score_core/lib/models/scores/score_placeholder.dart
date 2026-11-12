import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/score_placeholder_state.dart';
import '../id.dart';
import '../shared/shared.dart';

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
    this.revision = 0,
  }) : lockedAt = lockedAt?.toUtc() {
    requireNonNegative(scoreRevision, 'scoreRevision');
    if ((lockedBy == null) != (lockedAt == null)) {
      throw ArgumentError('locked_by and locked_at are set together');
    }
    requireNonNegative(revision, 'revision');
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

  @override
  final int revision;

  bool get isLocked => lockedAt != null;

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
    revision,
  ];
}
