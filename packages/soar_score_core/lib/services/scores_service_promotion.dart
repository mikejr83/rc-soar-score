part of 'scores_service.dart';

/// Official-selection reason code of an adopted submission, stored in the
/// official score's `reason` and localized where it is shown.
const directorAcceptedSubmissionReason = 'director_accepted_submission';

/// Reason code of a submission the contest made official on its own because
/// its round was fully scored (selection origin `Automatic`).
const automaticRoundCompleteReason = 'automatic_round_complete';

/// Reason code of a submission the contest made official on its own because
/// its flight group was fully scored (selection origin `Automatic`).
const automaticGroupCompleteReason = 'automatic_group_complete';

/// Reason code of a director's explicit confirmation of an automatically
/// accepted score. It closes review without a second official version.
const directorConfirmedAutomaticReason = 'director_confirmed_automatic';

/// Reason code of a review superseded by an official selection.
const supersededByOfficialSelectionReason = 'superseded_by_official_selection';

/// Raised inside a promotion pass that read a slot another request changed.
class _SlotMoved implements Exception {}

/// The `promote_score` intent of an installation that asked for an adoption.
class PromotionIntent {
  const PromotionIntent({
    required this.operationId,
    required this.clientMutationId,
    required this.data,
  });

  /// The intent's operation id.
  final Id operationId;

  /// The intent's `client_mutation_id`; the official score is stored under
  /// its own derived id.
  final String clientMutationId;

  /// The intent's payload data (assignment, source, expected revision).
  final Map<String, Object?> data;
}

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

/// The answer to a mark-official request on an installation: the adoption was
/// written, or it was queued as a `promote_score` intent that waits for the
/// service's decision.
class PromotionDecision extends Equatable {
  const PromotionDecision.adopted(ScorePromotionResult this.adopted)
    : queued = null;

  const PromotionDecision.queued(PendingPromotion this.queued) : adopted = null;

  /// An adoption as its JSON, or a queued intent as `{"queued": {...}}`.
  factory PromotionDecision.fromJson(Map<String, Object?> json) {
    final queued = json['queued'];
    return queued == null
        ? PromotionDecision.adopted(ScorePromotionResult.fromJson(json))
        : PromotionDecision.queued(
            PendingPromotion.fromJson(queued as Map<String, Object?>),
          );
  }

  final ScorePromotionResult? adopted;
  final PendingPromotion? queued;

  Map<String, Object?> toJson() =>
      queued != null ? {'queued': queued!.toJson()} : adopted!.toJson();

  @override
  List<Object?> get props => [adopted?.toJson(), queued];
}

/// Director adoption of a participant submission ("mark official").
extension PromoteSubmissionService on ScoresService {
  /// Marks the stored submission official the way this installation does it:
  /// written as [promoteSubmission] when the contest does not sync (or its
  /// first upload is not finished), otherwise queued as an intent.
  ///
  /// The queued intent changes no score, placeholder or review. It records
  /// only the director's request in the outbox, with the facts the service
  /// needs to refuse it when the slot has moved. A retry that names the same
  /// slot, source and revision as the pending intent returns that intent.
  /// Another request for a slot with a pending intent is a
  /// [ContestStateError] `promotion_pending`.
  ///
  /// The same errors as [promoteSubmission] are thrown for a slot the
  /// installation already knows to be stale, locked or unknown.
  Future<PromotionDecision> promoteOrQueue(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    if (!await _promotionIntents.queuesPromotions(contestId)) {
      return PromotionDecision.adopted(
        await promoteSubmission(
          contestId,
          assignmentId,
          sourceAttemptId: sourceAttemptId,
          expectedScoreRevision: expectedScoreRevision,
          actorId: actorId,
          metadata: metadata,
        ),
      );
    }
    return PromotionDecision.queued(
      await repository.officialScoreRepository.withContestGate(
        contestId,
        () => _queuePromotion(
          contestId,
          assignmentId,
          sourceAttemptId: sourceAttemptId,
          expectedScoreRevision: expectedScoreRevision,
          metadata: metadata,
        ),
      ),
    );
  }

  /// Whether [expectedScoreRevision] is the revision before the contest
  /// accepted [sourceAttemptId] automatically: a director who saw the score
  /// waiting may confirm it after the acceptance reached this installation.
  Future<bool> _namesAutomaticAcceptance(
    ScorePlaceholder placeholder,
    Id sourceAttemptId,
    int expectedScoreRevision,
  ) async {
    if (expectedScoreRevision != placeholder.scoreRevision - 1) return false;
    final official = await repository.officialScoreRepository
        .currentForPlaceholder(placeholder.id);
    return official != null &&
        official.selectionOrigin == SelectionOrigin.automatic &&
        official.scoreRevision == placeholder.scoreRevision &&
        official.scoreAttemptId == sourceAttemptId;
  }

  Future<PendingPromotion> _queuePromotion(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final pending = await repository.promotionIntentRepository
        .pendingForAssignment(contestId, assignmentId);
    if (pending != null) {
      if (pending.sourceAttemptId == sourceAttemptId &&
          pending.expectedScoreRevision == expectedScoreRevision) {
        return pending;
      }
      throw _promotionPending();
    }
    _requireScoringAllowed(contest);
    final slot = await _requireSlot(contestId, assignmentId);
    final placeholder = slot.placeholder;
    if (placeholder.isLocked) {
      throw ContestStateError(
        'score_locked',
        'this score is locked; unlock it to change it',
      );
    }
    if (placeholder.currentAttemptId != sourceAttemptId ||
        (placeholder.scoreRevision != expectedScoreRevision &&
            !await _namesAutomaticAcceptance(
              placeholder,
              sourceAttemptId,
              expectedScoreRevision,
            ))) {
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
    final intent = PendingPromotion(
      operationId: _newId(),
      contestId: contestId,
      assignmentId: assignmentId,
      sourceAttemptId: sourceAttemptId,
      expectedScoreRevision: expectedScoreRevision,
      queuedAt: metadata.clientTime.toUtc(),
    );
    await repository.promotionIntentRepository.queue(
      intent,
      metadata: metadata,
    );
    return intent;
  }

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
  /// The reads, checks and write run inside the contest's score gate, so a
  /// gated writer (director entry, participant submission, another promotion)
  /// cannot commit in between. A writer outside the gate, such as an accepted
  /// sync change, still can: whenever a pass fails or reads a slot that moved
  /// underneath it, the whole operation runs again from fresh reads (a few
  /// times at most). The retry of an adoption that won then replays, and one
  /// made stale by a competing entry is a [StaleRevisionError]. A failure
  /// with the slot unchanged is thrown as it is.
  Future<ScorePromotionResult> promoteSubmission(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
    PromotionIntent? intent,
  }) async {
    const passes = 4;
    for (var pass = 1; ; pass++) {
      final seen = <ScorePlaceholder>[];
      try {
        return await repository.officialScoreRepository.withContestGate(
          contestId,
          () => _promoteOnce(
            contestId,
            assignmentId,
            sourceAttemptId: sourceAttemptId,
            expectedScoreRevision: expectedScoreRevision,
            actorId: actorId,
            metadata: metadata,
            intent: intent,
            seen: seen,
          ),
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

  /// Closes every open review of [placeholder] as superseded by an official
  /// selection, with one audit event each.
  Future<({List<ReviewRequest> superseded, List<AuditEvent> audits})>
  _supersedeOpenReviews(
    ScorePlaceholder placeholder, {
    required Id actorId,
    required MutationMetadata metadata,
    required DateTime now,
    required Id sourceAttemptId,
    required Id officialScoreId,
  }) async {
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
          contestId: placeholder.contestId,
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
            'source_attempt_id': sourceAttemptId.value,
            'official_score_id': officialScoreId.value,
          }),
          outcome: AuditOutcome.success,
        ),
      );
    }
    return (superseded: superseded, audits: audits);
  }

  /// A director's confirmation of an automatically accepted score: the
  /// request names the submission the contest already made official. Review
  /// is closed on the placeholder ([ScorePlaceholder.reviewClosedScoreRevision])
  /// and open reviews are superseded; no second official version is written,
  /// and the result is not a replay. Returns null when the request is not
  /// such a confirmation (another score, a manual or review-decision
  /// version, an already confirmed or locked score), so the caller handles
  /// it as an adoption or a replay.
  ///
  /// The request may carry the score revision the director saw before the
  /// contest accepted the submission (one less than the official revision)
  /// or the accepted revision itself.
  Future<ScorePromotionResult?> _confirmAutomatic(
    Contest contest,
    _Configuration context,
    ScorePlaceholder current, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
    required PromotionIntent? intent,
  }) async {
    final official = await repository.officialScoreRepository
        .currentForPlaceholder(current.id);
    if (official == null ||
        official.selectionOrigin != SelectionOrigin.automatic ||
        official.scoreRevision != current.scoreRevision ||
        official.scoreAttemptId != sourceAttemptId ||
        current.currentAttemptId != sourceAttemptId ||
        current.hasReviewClosure ||
        current.isLocked ||
        (expectedScoreRevision != official.scoreRevision - 1 &&
            expectedScoreRevision != official.scoreRevision)) {
      return null;
    }
    _requireScoringAllowed(contest);
    // The same slot rules as an adoption: a locked round or group, a moved
    // assignment or a round no longer current refuse a fresh confirmation.
    await _requireSlot(contest.id, current.assignmentId);
    if (intent == null) {
      await _requireNoPendingPromotion(contest.id, current.assignmentId);
    }
    final now = _clock();
    final updated = ScorePlaceholder(
      id: current.id,
      contestId: current.contestId,
      contestParticipationId: current.contestParticipationId,
      assignmentId: current.assignmentId,
      state: current.state,
      scoreRevision: current.scoreRevision,
      currentAttemptId: current.currentAttemptId,
      lockedBy: current.lockedBy,
      lockedAt: current.lockedAt,
      reviewClosedScoreRevision: current.scoreRevision,
      revision: current.revision,
    );
    final (:superseded, :audits) = await _supersedeOpenReviews(
      current,
      actorId: actorId,
      metadata: metadata,
      now: now,
      sourceAttemptId: sourceAttemptId,
      officialScoreId: official.id,
    );
    final stored = await repository.officialScoreRepository.recordPromotion(
      PromotedScore(
        officialScore: official,
        placeholder: updated,
        supersededReviews: superseded,
        confirmsExisting: true,
        audits: [
          ...audits,
          AuditEvent(
            id: _newId(),
            entityType: current.entityType,
            entityId: current.id,
            contestId: current.contestId,
            action: AuditAction.scoreReview,
            actorId: actorId,
            authority: Authority.director,
            installationId: metadata.sourceInstallationId,
            device: metadata.sourceDevice,
            baseRevision: current.revision,
            resultingRevision: current.revision + 1,
            serverTimestamp: now,
            clientTimestamp: metadata.clientTime,
            reason: jsonEncode({
              'v': 1,
              'code': directorConfirmedAutomaticReason,
              'source_attempt_id': sourceAttemptId.value,
              'official_score_id': official.id.value,
            }),
            outcome: AuditOutcome.success,
          ),
        ],
        receipt: intent == null
            ? null
            : PromotionReceipt(
                operationId: intent.operationId,
                clientMutationId: intent.clientMutationId,
                payload: VersionedPayload(
                  version: 1,
                  data: {
                    ...intent.data,
                    'official_score_id': official.id.value,
                    'score_revision': official.scoreRevision,
                  },
                ).toJson(),
              ),
      ),
      metadata: metadata,
    );
    return ScorePromotionResult(
      entry: ScoreEntryResult(
        officialScore: official,
        placeholder: stored.placeholder,
        contest: contest,
        calculated: await _calculate(context, official.components),
      ),
      replayed: false,
    );
  }

  Future<ScorePromotionResult> _promoteOnce(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
    required PromotionIntent? intent,
    required List<ScorePlaceholder> seen,
  }) async {
    final contest = await _requireContest(contestId);
    final context = await _configuration(contest);

    final current = await repository.scorePlaceholderRepository
        .findForAssignmentForUpdate(assignmentId);
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
          (official.scoreRevision - 1 == expectedScoreRevision ||
              // A confirmed automatic score also answers its own accepted
              // revision, one of the two a confirmation may name.
              (official.selectionOrigin == SelectionOrigin.automatic &&
                  official.scoreRevision == expectedScoreRevision))) {
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

    final confirmed = await _confirmAutomatic(
      contest,
      context,
      current,
      sourceAttemptId: sourceAttemptId,
      expectedScoreRevision: expectedScoreRevision,
      actorId: actorId,
      metadata: metadata,
      intent: intent,
    );
    if (confirmed != null) return confirmed;
    final earlier = await replayOf(current);
    if (earlier != null) return earlier;

    _requireScoringAllowed(contest);
    final slot = await _requireSlot(contestId, assignmentId);
    final placeholder = slot.placeholder;
    if (intent == null) {
      await _requireNoPendingPromotion(contestId, assignmentId);
    }
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
      selectionOrigin: SelectionOrigin.manual,
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

    final (:superseded, :audits) = await _supersedeOpenReviews(
      placeholder,
      actorId: actorId,
      metadata: metadata,
      now: now,
      sourceAttemptId: attempt.id,
      officialScoreId: adopted.id,
    );

    final stored = await repository.officialScoreRepository.recordPromotion(
      PromotedScore(
        officialScore: adopted,
        placeholder: updated,
        supersededReviews: superseded,
        audits: audits,
        receipt: intent == null
            ? null
            : PromotionReceipt(
                operationId: intent.operationId,
                clientMutationId: intent.clientMutationId,
                payload: VersionedPayload(
                  version: 1,
                  data: {
                    ...intent.data,
                    'official_score_id': adopted.id.value,
                    'score_revision': adopted.scoreRevision,
                  },
                ).toJson(),
              ),
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
  }) : invalidMessage = null;

  /// A slot whose request cannot be carried out as written (for example a
  /// malformed source id); it is refused on its own with [invalidMessage]
  /// while its peers are processed.
  const PromotionItem.invalid({
    required this.assignmentId,
    required String this.invalidMessage,
  }) : sourceAttemptId = null,
       expectedScoreRevision = 0;

  final Id assignmentId;
  final Id? sourceAttemptId;
  final int expectedScoreRevision;
  final String? invalidMessage;

  @override
  List<Object?> get props => [
    assignmentId,
    sourceAttemptId,
    expectedScoreRevision,
    invalidMessage,
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
      message = null,
      queued = null;

  const PromotionOutcome.refused(
    this.assignmentId, {
    required int this.statusCode,
    required String this.code,
    required String this.message,
  }) : promotion = null,
       queued = null;

  /// The slot's adoption was queued for the service to decide.
  const PromotionOutcome.queued(this.assignmentId, PendingPromotion this.queued)
    : promotion = null,
      statusCode = null,
      code = null,
      message = null;

  factory PromotionOutcome.fromJson(Map<String, Object?> json) {
    final assignmentId = Id.parse(json['assignment_id']! as String);
    final result = json['result'];
    if (result != null) {
      return PromotionOutcome.adopted(
        assignmentId,
        ScorePromotionResult.fromJson(result as Map<String, Object?>),
      );
    }
    final queued = json['queued'];
    if (queued != null) {
      return PromotionOutcome.queued(
        assignmentId,
        PendingPromotion.fromJson(queued as Map<String, Object?>),
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

  /// The queued intent, or null when the slot was adopted or refused.
  final PendingPromotion? queued;

  /// Whether the slot now holds the requested adoption.
  bool get isAdopted => promotion != null;

  /// Whether the adoption waits for the service's decision.
  bool get isQueued => queued != null;

  Map<String, Object?> toJson() => {
    'assignment_id': assignmentId.value,
    if (promotion != null)
      'result': promotion!.toJson()
    else if (queued != null)
      'queued': queued!.toJson()
    else
      'error': {'status': statusCode, 'code': code, 'message': message},
  };

  @override
  List<Object?> get props => [
    assignmentId,
    promotion?.toJson(),
    queued,
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
      final invalid = item.invalidMessage;
      if (invalid != null) {
        outcomes.add(
          PromotionOutcome.refused(
            item.assignmentId,
            statusCode: 400,
            code: 'invalid_request',
            message: invalid,
          ),
        );
        continue;
      }
      try {
        final decision = await promoteOrQueue(
          contestId,
          item.assignmentId,
          sourceAttemptId: item.sourceAttemptId!,
          expectedScoreRevision: item.expectedScoreRevision,
          actorId: actorId,
          metadata: metadata.forPart(item.assignmentId.value),
        );
        outcomes.add(
          decision.queued != null
              ? PromotionOutcome.queued(item.assignmentId, decision.queued!)
              : PromotionOutcome.adopted(item.assignmentId, decision.adopted!),
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
