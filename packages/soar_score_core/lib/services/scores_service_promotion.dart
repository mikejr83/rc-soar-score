part of 'scores_service.dart';

/// Official-selection reason code of an adopted submission, stored in the
/// official score's `reason` and localized where it is shown.
const directorAcceptedSubmissionReason = 'director_accepted_submission';

/// Reason code of a review superseded by an official selection.
const supersededByOfficialSelectionReason = 'superseded_by_official_selection';

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
  Future<ScorePromotionResult> promoteSubmission(
    Id contestId,
    Id assignmentId, {
    required Id sourceAttemptId,
    required int expectedScoreRevision,
    required Id actorId,
    required MutationMetadata metadata,
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
    final official = await repository.officialScoreRepository
        .currentForPlaceholder(current.id);
    if (official != null) {
      // Only an exact retry of this adoption is a success; it reads state and
      // writes nothing, whatever locks were set since.
      if (official.scoreAttemptId == sourceAttemptId &&
          current.currentAttemptId == sourceAttemptId &&
          official.scoreRevision - 1 == expectedScoreRevision) {
        return ScorePromotionResult(
          entry: ScoreEntryResult(
            officialScore: official,
            placeholder: current,
            contest: contest,
            calculated: await _calculate(context, official.components),
          ),
          replayed: true,
        );
      }
      throw StaleRevisionError(
        entityType: 'ScorePlaceholder',
        entityId: current.id,
        expectedRevision: expectedScoreRevision,
        storedRevision: current.scoreRevision,
      );
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
