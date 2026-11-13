part of 'scores_service.dart';

/// Official-selection reason code of an adopted submission, stored in the
/// official score's `reason` and localized where it is shown.
const directorAcceptedSubmissionReason = 'director_accepted_submission';

/// Reason code of a review superseded by an official selection.
const supersededByOfficialSelectionReason = 'superseded_by_official_selection';

/// Raised inside a promotion pass that read a slot another request changed.
class _SlotMoved implements Exception {}

/// The outcome of adopting a stored submission as official.
class ScorePromotionResult {
  const ScorePromotionResult({required this.entry, required this.replayed});

  /// The authoritative official score, placeholder and contest.
  final ScoreEntryResult entry;

  /// True when this exact adoption was already done and nothing was stored.
  final bool replayed;

  factory ScorePromotionResult.fromJson(Map<String, Object?> json) =>
      ScorePromotionResult(
        entry: ScoreEntryResult.fromJson(json),
        replayed: json['replayed']! as bool,
      );

  /// The entry's JSON plus `replayed`.
  Map<String, Object?> toJson() => {...entry.toJson(), 'replayed': replayed};
}

/// Director adoption of a participant submission ("mark official").
extension PromoteSubmissionService on ScoresService {
  /// Makes the stored submission [sourceAttemptId] of the slot
  /// [assignmentId] its official score. [expectedScoreRevision] is the score
  /// revision the director saw on the slot.
  ///
  /// The new official version cites the submission, so the participant's
  /// original values and authorship stay on record. Open reviews of the slot
  /// are superseded without applying their proposals.
  ///
  /// A retry of an adoption that already happened returns it with
  /// [ScorePromotionResult.replayed]. Any other mismatch of source or revision
  /// is a [StaleRevisionError]; a newer official score is never overwritten.
  /// Throws a [ContestStateError] for a locked contest, round, group or score,
  /// a [ScoringValidationError] for stored values the discipline now refuses,
  /// and an [EntityNotFoundError] for an unknown contest, slot or source.
  ///
  /// The checks read several rows and the write is its own transaction, so
  /// another request can commit in between. Whenever a pass fails or reads a
  /// slot that moved underneath it, the whole operation runs again from fresh
  /// reads (a few times at most): the retry of an adoption that won then
  /// replays, and one made stale by a competing entry is a
  /// [StaleRevisionError]. A failure with the slot unchanged is thrown as it
  /// is.
  Future<ScorePromotionResult> promoteSubmission(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    const passes = 4;
    for (var pass = 1; ; pass++) {
      final seen = <ScorePlaceholder>[];
      try {
        return await _promoteOnce(
          contestId,
          assignmentId,
          sourceAttemptId: sourceAttemptId,
          expectedScoreRevision: expectedScoreRevision,
          actorId: actorId,
          metadata: metadata,
          seen: seen,
        );
      } on Object catch (error) {
        var moved = error is _SlotMoved;
        if (!moved && seen.isNotEmpty) {
          final after = await repository.scorePlaceholderRepository
              .findForAssignment(assignmentId);
          moved = after != null && after.revision != seen.first.revision;
        }
        if (!moved) rethrow;
        if (pass >= passes) {
          throw StaleRevisionError(
            entityType: 'ScorePlaceholder',
            entityId: seen.isEmpty ? assignmentId : seen.first.id,
            expectedRevision: expectedScoreRevision,
            storedRevision: seen.isEmpty ? 0 : seen.first.scoreRevision,
          );
        }
      }
    }
  }

  Future<ScorePromotionResult> _promoteOnce(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
    required List<ScorePlaceholder> seen,
  }) async {
    final contest = await _requireContest(contestId);
    final context = await _configuration(contest);

    final current = await repository.scorePlaceholderRepository
        .findForAssignment(assignmentId);
    if (current == null || current.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'ScorePlaceholder',
        entityId: assignmentId,
      );
    }
    seen.add(current);
    Future<ScorePromotionResult?> replayOf(ScorePlaceholder slot) async {
      final official = await repository.officialScoreRepository
          .currentForPlaceholder(slot.id);
      if (official == null) return null;
      // The placeholder was read before a commit that this official score
      // belongs to: the two reads are not one state.
      if (official.scoreRevision != slot.scoreRevision) throw _SlotMoved();
      // Only an exact retry of this adoption is a success; it reads state and
      // writes nothing, whatever locks were set since.
      if (official.scoreAttemptId == sourceAttemptId &&
          slot.currentAttemptId == sourceAttemptId &&
          official.scoreRevision - 1 == expectedScoreRevision) {
        return ScorePromotionResult(
          entry: ScoreEntryResult(
            officialScore: official,
            placeholder: slot,
            contest: contest,
            calculated: await _calculate(context, official.components),
          ),
          replayed: true,
        );
      }
      throw StaleRevisionError(
        entityType: 'ScorePlaceholder',
        entityId: slot.id,
        expectedRevision: expectedScoreRevision,
        storedRevision: slot.scoreRevision,
      );
    }

    final earlier = await replayOf(current);
    if (earlier != null) return earlier;

    _requireScoringAllowed(contest);
    final slot = await _requireSlot(contestId, assignmentId);
    final placeholder = slot.placeholder;
    if (placeholder.revision != current.revision) throw _SlotMoved();
    if (placeholder.isLocked) {
      throw ContestStateError(
        'score_locked',
        'this score is locked; unlock it to change it',
      );
    }
    if (placeholder.currentAttemptId != sourceAttemptId ||
        placeholder.scoreRevision != expectedScoreRevision) {
      throw StaleRevisionError(
        entityType: 'ScorePlaceholder',
        entityId: placeholder.id,
        expectedRevision: expectedScoreRevision,
        storedRevision: placeholder.scoreRevision,
      );
    }
    final attempt = await repository.scoreAttemptRepository.findById(
      sourceAttemptId,
    );
    if (attempt == null ||
        attempt.contestId != contestId ||
        attempt.scorePlaceholderId != placeholder.id) {
      throw EntityNotFoundError(
        entityType: 'ScoreAttempt',
        entityId: sourceAttemptId,
      );
    }

    final calculated = await _calculate(context, attempt.rawComponents);
    final now = _clock();
    final adopted = OfficialScore(
      id: _newId(),
      contestId: contestId,
      scorePlaceholderId: placeholder.id,
      scoreAttemptId: attempt.id,
      scoreRevision: placeholder.scoreRevision + 1,
      components: attempt.rawComponents,
      setAt: now,
      setBy: actorId,
      reason: directorAcceptedSubmissionReason,
    );
    final updated = ScorePlaceholder(
      id: placeholder.id,
      contestId: contestId,
      contestParticipationId: placeholder.contestParticipationId,
      assignmentId: placeholder.assignmentId,
      state: ScorePlaceholderState.official,
      scoreRevision: adopted.scoreRevision,
      currentAttemptId: attempt.id,
      lockedBy: placeholder.lockedBy,
      lockedAt: placeholder.lockedAt,
      revision: placeholder.revision,
    );

    final superseded = <ReviewRequest>[];
    final audits = <AuditEvent>[];
    for (final review
        in await repository.reviewRequestRepository.listForScorePlaceholder(
          placeholder.id,
        )) {
      if (!review.isOpen) continue;
      superseded.add(
        ReviewRequest(
          id: review.id,
          contestId: review.contestId,
          scorePlaceholderId: review.scorePlaceholderId,
          proposedComponents: review.proposedComponents,
          participantMessage: review.participantMessage,
          requesterId: review.requesterId,
          baseScoreRevision: review.baseScoreRevision,
          requestedAt: review.requestedAt,
          state: ReviewRequestState.superseded,
          decisionActorId: actorId,
          decisionTime: now,
          decisionMessage: supersededByOfficialSelectionReason,
          revision: review.revision,
        ),
      );
      audits.add(
        AuditEvent(
          id: _newId(),
          entityType: review.entityType,
          entityId: review.id,
          contestId: contestId,
          action: AuditAction.scoreReview,
          actorId: actorId,
          authority: Authority.director,
          installationId: metadata.sourceInstallationId,
          device: metadata.sourceDevice,
          baseRevision: review.revision,
          resultingRevision: review.revision + 1,
          serverTimestamp: now,
          clientTimestamp: metadata.clientTime,
          reason: jsonEncode({
            'v': 1,
            'code': supersededByOfficialSelectionReason,
            'source_attempt_id': attempt.id.value,
            'official_score_id': adopted.id.value,
          }),
          outcome: AuditOutcome.success,
        ),
      );
    }

    final stored = await repository.officialScoreRepository.recordPromotion(
      PromotedScore(
        officialScore: adopted,
        placeholder: updated,
        supersededReviews: superseded,
        audits: audits,
      ),
      metadata: metadata,
    );
    return ScorePromotionResult(
      entry: ScoreEntryResult(
        officialScore: stored.officialScore,
        placeholder: stored.placeholder,
        contest: contest,
        calculated: calculated,
      ),
      replayed: false,
    );
  }
}

/// One slot of a group promotion: the submission the director saw.
class PromotionItem extends Equatable {
  const PromotionItem({
    required this.assignmentId,
    required this.sourceAttemptId,
    required this.expectedScoreRevision,
  });

  final Id assignmentId;
  final Id sourceAttemptId;
  final int expectedScoreRevision;

  @override
  List<Object?> get props => [
    assignmentId,
    sourceAttemptId,
    expectedScoreRevision,
  ];
}

/// What happened to one requested slot of a group promotion: it was adopted
/// or replayed ([result]), or refused ([statusCode], [code], [message]) as a
/// single promotion would have answered.
class PromotionOutcome extends Equatable {
  const PromotionOutcome.adopted(
    this.assignmentId,
    ScorePromotionResult this.promotion,
  ) : statusCode = null,
      code = null,
      message = null;

  const PromotionOutcome.refused(
    this.assignmentId, {
    required int this.statusCode,
    required String this.code,
    required String this.message,
  }) : promotion = null;

  factory PromotionOutcome.fromJson(Map<String, Object?> json) {
    final assignmentId = Id.parse(json['assignment_id']! as String);
    final result = json['result'];
    if (result != null) {
      return PromotionOutcome.adopted(
        assignmentId,
        ScorePromotionResult.fromJson(result as Map<String, Object?>),
      );
    }
    final error = json['error']! as Map<String, Object?>;
    return PromotionOutcome.refused(
      assignmentId,
      statusCode: error['status']! as int,
      code: error['code']! as String,
      message: error['message']! as String,
    );
  }

  final Id assignmentId;

  /// The adoption (or its replay), or null when the slot was refused.
  final ScorePromotionResult? promotion;
  final int? statusCode;
  final String? code;
  final String? message;

  /// Whether the slot now holds the requested adoption.
  bool get isAdopted => promotion != null;

  Map<String, Object?> toJson() => {
    'assignment_id': assignmentId.value,
    if (promotion != null)
      'result': promotion!.toJson()
    else
      'error': {'status': statusCode, 'code': code, 'message': message},
  };

  @override
  List<Object?> get props => [
    assignmentId,
    promotion?.toJson(),
    statusCode,
    code,
    message,
  ];
}

/// The answer to a group promotion.
class GroupPromotionResult extends Equatable {
  const GroupPromotionResult({
    required this.outcomes,
    required this.notRequested,
    this.recalculationWarning,
  });

  factory GroupPromotionResult.fromJson(Map<String, Object?> json) =>
      GroupPromotionResult(
        outcomes: [
          for (final item in json['outcomes']! as List<Object?>)
            PromotionOutcome.fromJson(item! as Map<String, Object?>),
        ],
        notRequested: [
          for (final id in json['not_requested']! as List<Object?>)
            Id.parse(id! as String),
        ],
        recalculationWarning: json['recalculation_warning'] as String?,
      );

  /// One outcome per requested slot, in request order.
  final List<PromotionOutcome> outcomes;

  /// Live slots of the group the request did not name; never promoted.
  final List<Id> notRequested;

  /// Set by the caller when the recalculation after the adoptions failed.
  final String? recalculationWarning;

  GroupPromotionResult withWarning(String? warning) => GroupPromotionResult(
    outcomes: outcomes,
    notRequested: notRequested,
    recalculationWarning: warning,
  );

  Map<String, Object?> toJson() => {
    'outcomes': [for (final outcome in outcomes) outcome.toJson()],
    'not_requested': [for (final id in notRequested) id.value],
    'recalculation_warning': recalculationWarning,
  };

  @override
  List<Object?> get props => [outcomes, notRequested, recalculationWarning];
}

/// Director adoption of the submissions of one group.
extension PromoteGroupService on ScoresService {
  /// Adopts each of [items], the submissions the director saw in the group
  /// [group] of round [roundId], with the rules of [promoteSubmission].
  ///
  /// A slot that is stale, locked or invalid is refused alone and the others
  /// go on, each stored on its own. Live slots of the group that are not in
  /// [items] are never promoted and are listed in
  /// [GroupPromotionResult.notRequested]. Throws an [ArgumentError] for an
  /// empty list, a repeated slot or a slot outside the group, and an
  /// [EntityNotFoundError] for an unknown contest or round.
  Future<GroupPromotionResult> promoteGroup(
    Id contestId,
    Id roundId,
    int group,
    List<PromotionItem> items, {
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    await _requireContest(contestId);
    final round = await repository.roundRepository.findById(roundId);
    if (round == null || round.contestId != contestId) {
      throw EntityNotFoundError(entityType: 'Round', entityId: roundId);
    }
    if (items.isEmpty) {
      throw ArgumentError('a group promotion needs at least one slot');
    }
    final live = [
      for (final assignment
          in await repository.matrixAssignmentRepository.listLiveForRound(
            roundId,
          ))
        if (assignment.group == group) assignment.id,
    ];
    final requested = <Id>{};
    for (final item in items) {
      if (!requested.add(item.assignmentId)) {
        throw ArgumentError('the request names a slot twice');
      }
      if (!live.contains(item.assignmentId)) {
        throw ArgumentError('a slot is not in group $group of this round');
      }
    }

    final outcomes = <PromotionOutcome>[];
    for (final item in items) {
      try {
        outcomes.add(
          PromotionOutcome.adopted(
            item.assignmentId,
            await promoteSubmission(
              contestId,
              item.assignmentId,
              sourceAttemptId: item.sourceAttemptId,
              expectedScoreRevision: item.expectedScoreRevision,
              actorId: actorId,
              metadata: metadata.forPart(item.assignmentId.value),
            ),
          ),
        );
      } on Object catch (error) {
        final refused = _refusal(error);
        if (refused == null) rethrow;
        outcomes.add(
          PromotionOutcome.refused(
            item.assignmentId,
            statusCode: refused.statusCode!,
            code: refused.code!,
            message: refused.message!,
          ),
        );
      }
    }
    return GroupPromotionResult(
      outcomes: outcomes,
      notRequested: [
        for (final id in live)
          if (!requested.contains(id)) id,
      ],
    );
  }
}
