import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/review_request_state.dart';
import '../id.dart';
import '../shared/shared.dart';
import 'score_components.dart';

part 'review_request.g.dart';

/// A participant's proposed revised score, kept beside the original.
///
/// Approving it creates a new attempt and official version; it never edits
/// the original. See `plan/data-model/entities/review_request.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ReviewRequest extends Equatable implements Synchronizable {
  ReviewRequest({
    required this.id,
    required this.contestId,
    required this.scorePlaceholderId,
    required Map<String, Object?> proposedComponents,
    this.participantMessage,
    required this.requesterId,
    required this.baseScoreRevision,
    required DateTime requestedAt,
    this.state = ReviewRequestState.submitted,
    this.decisionActorId,
    DateTime? decisionTime,
    this.decisionMessage,
    this.resultingAttemptId,
    this.revision = 0,
  }) : proposedComponents = Map.unmodifiable(proposedComponents),
       requestedAt = requestedAt.toUtc(),
       decisionTime = decisionTime?.toUtc() {
    if (proposedComponents.containsKey('cumulative_penalty')) {
      throw ArgumentError('a review request cannot propose cumulative_penalty');
    }
    requireValidPenalties(proposedComponents);
    requireNonNegative(baseScoreRevision, 'baseScoreRevision');
    _checkDecision();
    requireNonNegative(revision, 'revision');
  }

  factory ReviewRequest.fromJson(Map<String, Object?> json) =>
      _$ReviewRequestFromJson(json);

  void _checkDecision() {
    if ((decisionActorId == null) != (decisionTime == null)) {
      throw ArgumentError(
        'decision_actor_id and decision_time are set together',
      );
    }
    if (state == ReviewRequestState.submitted &&
        (decisionActorId != null ||
            decisionMessage != null ||
            resultingAttemptId != null)) {
      throw ArgumentError('a Submitted request has no decision yet');
    }
    final decided =
        state == ReviewRequestState.approved ||
        state == ReviewRequestState.rejected;
    if (decided && decisionActorId == null) {
      throw ArgumentError('a decided request records who decided and when');
    }
    if ((state == ReviewRequestState.approved) !=
        (resultingAttemptId != null)) {
      throw ArgumentError(
        'resulting_attempt_id is set exactly when the request is Approved',
      );
    }
  }

  @override
  final Id id;
  final Id contestId;
  final Id scorePlaceholderId;

  /// Each scoring component mapped to its proposed value.
  final Map<String, Object?> proposedComponents;

  final String? participantMessage;
  final Id requesterId;

  /// The score revision at the time of the request.
  final int baseScoreRevision;

  final DateTime requestedAt;
  final ReviewRequestState state;
  final Id? decisionActorId;
  final DateTime? decisionTime;
  final String? decisionMessage;

  /// The attempt created on approval.
  final Id? resultingAttemptId;

  @override
  final int revision;

  /// Whether the request is still waiting on a decision.
  bool get isOpen =>
      state == ReviewRequestState.submitted ||
      state == ReviewRequestState.underReview;

  @override
  String get entityType => 'ReviewRequest';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ReviewRequestToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    scorePlaceholderId,
    proposedComponents,
    participantMessage,
    requesterId,
    baseScoreRevision,
    requestedAt,
    state,
    decisionActorId,
    decisionTime,
    decisionMessage,
    resultingAttemptId,
    revision,
  ];
}
