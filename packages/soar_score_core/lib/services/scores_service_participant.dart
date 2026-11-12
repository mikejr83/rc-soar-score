part of 'scores_service.dart';

/// A pilot's own score submission (`POST /self-scoring/rounds/{round}/scores`),
/// on top of the checks and the store of a director's entry.
extension ParticipantScoresService on ScoresService {
  /// Stores the score the pilot of [access] submits for [round], as a
  /// preliminary score.
  ///
  /// The pilot and the slot come from [access] and the current matrix, never
  /// from the request. The submission is stored as a score attempt with
  /// authority `Participant` (the guest as actor, the invitation as access
  /// reference) and the slot becomes `Submitted`; no official score is made,
  /// so official results and the public site do not see it. A `Ready`
  /// contest moves to `Running` in the same transaction. The director's own
  /// entry for the slot is what makes it official.
  ///
  /// A repeat of [clientMutationId] with the same components returns the
  /// first answer ([ParticipantSubmission.replayed]); with other components
  /// it is a `mutation_conflict`.
  ///
  /// Throws a [ParticipantSubmissionRefusal] for a stale matrix, a round that
  /// is not the pilot's next, a slot that already has a score, a rejected
  /// field (the cumulative penalty is never accepted) or a reused mutation
  /// id; an [EntityNotFoundError] when the pilot has no flight in [round];
  /// and a [ContestStateError] for a locked group or score, a retired pilot
  /// or a contest that takes no scores.
  Future<ParticipantSubmission> submitParticipantScore(
    ParticipantAccess access,
    int round, {
    required String clientMutationId,
    required int matrixRevision,
    required Map<String, Object?> components,
    String? sourceDevice,
  }) async {
    final contest = await _requireContest(access.contestId);
    final context = await _configuration(contest);

    // A repeat is answered from the stored attempt, before the current
    // matrix is looked at: a redraw since the first request must not turn an
    // accepted submission into a failure.
    final earlier = await repository.scoreAttemptRepository
        .findByClientMutationId(contest.id, clientMutationId);
    if (earlier != null) {
      return _participantReplay(access, round, context, earlier, components);
    }
    final slot = await _participantSlot(access, round);

    final revision = await repository.matrixRevisionRepository.findById(
      slot.assignment.matrixRevisionId,
    );
    final latest = await repository.matrixRevisionRepository.latestForContest(
      contest.id,
    );
    if (revision == null ||
        latest == null ||
        revision.id != latest.id ||
        revision.revisionNumber != matrixRevision) {
      throw ParticipantSubmissionRefusal(
        409,
        'stale_matrix',
        'the draw changed since you opened this round; reload it',
      );
    }

    if (slot.placeholder.scoreRevision > 0) {
      throw ParticipantSubmissionRefusal(
        409,
        'score_already_submitted',
        'this flight already has a score',
        accepted: await _accepted(context, slot, round),
      );
    }
    final next = await _nextParticipantRound(access, round);
    if (next.earlierUnscored != null) {
      throw ParticipantSubmissionRefusal(
        409,
        'out_of_order',
        'round ${next.earlierUnscored} has to be scored first',
      );
    }

    final fieldErrors = _participantFieldErrors(context, components);
    if (fieldErrors.isNotEmpty) {
      throw ParticipantSubmissionRefusal(
        400,
        'validation_failed',
        'the score has fields that are missing or not allowed',
        fieldErrors: fieldErrors,
      );
    }

    _requireScoringAllowed(contest);
    if (slot.placeholder.isLocked) {
      throw ContestStateError(
        'score_locked',
        'this score is locked; ask the director',
      );
    }
    final CalculatedFlight calculated;
    try {
      calculated = await _calculate(context, components);
    } on ScoringValidationError catch (error) {
      throw ParticipantSubmissionRefusal(
        400,
        'validation_failed',
        'the score has fields that are missing or not allowed',
        fieldErrors: _issueFieldErrors(error.issues),
      );
    }

    // The pilot's score is preliminary: an attempt and a `Submitted` slot,
    // no official score. The director's entry makes it official.
    final now = _clock();
    final attempt = ScoreAttempt(
      id: _newId(),
      contestId: contest.id,
      scorePlaceholderId: slot.placeholder.id,
      configRevisionId: context.revision.id,
      matrixRevisionId: slot.assignment.matrixRevisionId,
      rawComponents: components,
      actorId: access.guestAccountId,
      authority: Authority.participant,
      invitationId: access.invitation.id,
      sourceDevice: sourceDevice,
      clientMutationId: clientMutationId,
      baseScoreRevision: 0,
      acceptedAt: now,
    );
    final placeholder = ScorePlaceholder(
      id: slot.placeholder.id,
      contestId: contest.id,
      contestParticipationId: slot.placeholder.contestParticipationId,
      assignmentId: slot.placeholder.assignmentId,
      state: ScorePlaceholderState.submitted,
      scoreRevision: 1,
      currentAttemptId: attempt.id,
      lockedBy: slot.placeholder.lockedBy,
      lockedAt: slot.placeholder.lockedAt,
      revision: slot.placeholder.revision,
    );
    final metadata = MutationMetadata(
      clientMutationId: clientMutationId,
      authority: Authority.participant,
      clientTime: now,
      actorId: access.guestAccountId,
    );
    try {
      await repository.scoreAttemptRepository.recordAttempt(
        attempt,
        placeholder,
        contest: contest.lifecycleState == LifecycleState.ready
            ? contest.copyWithState(
                lifecycleState: LifecycleState.running,
                updatedAt: now,
              )
            : null,
        metadata: metadata,
      );
    } on SyncConstraintError catch (error) {
      // A concurrent request with the same id stored its attempt first: this
      // one is a repeat of it.
      if (error.kind != SyncConstraintKind.unique) rethrow;
      final winner = await repository.scoreAttemptRepository
          .findByClientMutationId(contest.id, clientMutationId);
      if (winner == null) rethrow;
      return _participantReplay(access, round, context, winner, components);
    } on StaleRevisionError {
      // A concurrent request stored a score for the slot first.
      final current = await repository.scorePlaceholderRepository
          .findForAssignment(slot.assignment.id);
      if (current == null || current.scoreRevision == 0) rethrow;
      throw ParticipantSubmissionRefusal(
        409,
        'score_already_submitted',
        'this flight already has a score',
        accepted: await _accepted(
          context,
          _Slot(slot.assignment, current, round: slot.round),
          round,
        ),
      );
    }
    return ParticipantSubmission(
      assignmentId: slot.assignment.id,
      round: round,
      components: components,
      revision: 1,
      enteredAt: attempt.acceptedAt,
      calculated: calculated,
      authority: Authority.participant,
      nextRound: (await _nextParticipantRound(access, round)).after,
    );
  }

  /// The pilot's live flight in [round] of the current matrix.
  Future<_Slot> _participantSlot(ParticipantAccess access, int round) async {
    final rounds = (await repository.roundRepository.listForContest(
      access.contestId,
    )).where((r) => r.isCurrent && r.ordinal == round);
    for (final r in rounds) {
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        r.id,
      );
      for (final assignment in live) {
        if (assignment.contestParticipationId != access.participationId) {
          continue;
        }
        return _requireSlot(access.contestId, assignment.id);
      }
    }
    throw EntityNotFoundError(
      entityType: 'Round',
      entityId: access.participationId,
    );
  }

  /// The rounds around [round] for the pilot: [_NextRound.earlierUnscored] is
  /// the first earlier round without a score (the pilot may not skip it) and
  /// [_NextRound.after] the first later round without one.
  Future<_NextRound> _nextParticipantRound(
    ParticipantAccess access,
    int round,
  ) async {
    final rounds =
        (await repository.roundRepository.listForContest(access.contestId))
            .where((r) => r.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    int? earlier;
    int? after;
    for (final r in rounds) {
      if (r.ordinal == round) continue;
      if (access.participation.hasRetiredBy(r.ordinal)) continue;
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        r.id,
      );
      final mine = live
          .where((a) => a.contestParticipationId == access.participationId)
          .firstOrNull;
      if (mine == null) continue;
      final placeholder = await repository.scorePlaceholderRepository
          .findForAssignment(mine.id);
      if (placeholder == null || placeholder.scoreRevision > 0) continue;
      if (r.ordinal < round) {
        earlier ??= r.ordinal;
      } else {
        after ??= r.ordinal;
      }
    }
    return _NextRound(earlier, after);
  }

  /// The first answer to a mutation id that was stored before, worked out
  /// from the stored attempt: it must be this pilot's own submission for
  /// [round] with the same components, else the id was reused
  /// (`mutation_conflict`). The next round is worked out from the pilot's
  /// scores now.
  Future<ParticipantSubmission> _participantReplay(
    ParticipantAccess access,
    int round,
    _Configuration context,
    ScoreAttempt earlier,
    Map<String, Object?> components,
  ) async {
    final placeholder = await repository.scorePlaceholderRepository.findById(
      earlier.scorePlaceholderId,
    );
    final assignment = placeholder == null
        ? null
        : await repository.matrixAssignmentRepository.findById(
            placeholder.assignmentId,
          );
    final scheduled = assignment == null
        ? null
        : await repository.roundRepository.findById(
            assignment.scheduledRoundId,
          );
    if (placeholder == null ||
        assignment == null ||
        scheduled == null ||
        earlier.contestId != access.contestId ||
        placeholder.contestParticipationId != access.participationId ||
        scheduled.ordinal != round ||
        earlier.authority != Authority.participant ||
        !_sameComponents(earlier.rawComponents, components)) {
      throw ParticipantSubmissionRefusal(
        409,
        'mutation_conflict',
        'this request id was already used for a different score',
      );
    }
    return ParticipantSubmission(
      assignmentId: assignment.id,
      round: round,
      components: earlier.rawComponents,
      revision: 1,
      enteredAt: earlier.acceptedAt,
      calculated: await _calculate(context, earlier.rawComponents),
      authority: Authority.participant,
      nextRound: (await _nextParticipantRound(access, round)).after,
      replayed: true,
    );
  }

  /// The score that stands on the slot, for `score_already_submitted`: the
  /// director's official score when there is one, else the pilot's attempt.
  Future<ParticipantSubmission> _accepted(
    _Configuration context,
    _Slot slot,
    int round,
  ) async {
    final official = await repository.officialScoreRepository
        .currentForPlaceholder(slot.placeholder.id);
    if (official != null) {
      return ParticipantSubmission(
        assignmentId: slot.assignment.id,
        round: round,
        components: official.components,
        revision: official.scoreRevision,
        enteredAt: official.setAt,
        calculated: await _calculate(context, official.components),
        authority: Authority.director,
      );
    }
    final attempt = (await repository.scoreAttemptRepository
        .latestForPlaceholder(slot.placeholder.id))!;
    return ParticipantSubmission(
      assignmentId: slot.assignment.id,
      round: round,
      components: attempt.rawComponents,
      revision: slot.placeholder.scoreRevision,
      enteredAt: attempt.acceptedAt,
      calculated: await _calculate(context, attempt.rawComponents),
      authority: attempt.authority,
    );
  }

  List<SubmissionFieldError> _participantFieldErrors(
    _Configuration context,
    Map<String, Object?> components,
  ) => [
    // Only the director applies the cumulative penalty, whatever its value.
    if (components.containsKey('cumulative_penalty'))
      const SubmissionFieldError('cumulative_penalty', 'not_allowed'),
  ];

  List<SubmissionFieldError> _issueFieldErrors(List<ScoringIssue> issues) => [
    for (final issue in issues)
      SubmissionFieldError(issue.fieldId ?? 'score', switch (issue.code) {
        'required' => 'required',
        'unknown_field' || 'derived_field' => 'not_allowed',
        'wrong_type' || 'invalid_type' => 'wrong_type',
        'not_allowed' => 'not_allowed',
        _ => 'out_of_range',
      }),
  ];

  bool _sameComponents(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

class _NextRound {
  const _NextRound(this.earlierUnscored, this.after);

  final int? earlierUnscored;
  final int? after;
}
