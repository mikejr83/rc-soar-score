part of 'scores_service.dart';

/// A pilot's own score submission (`POST /self-scoring/rounds/{round}/scores`),
/// on top of the checks and the store of a director's entry.
extension ParticipantScoresService on ScoresService {
  /// The reason stored with a score the pilot submitted.
  static const String participantReason = 'Entered by the pilot';

  /// Stores the score the pilot of [access] submits for [round].
  ///
  /// The pilot and the slot come from [access] and the current matrix, never
  /// from the request. The submission becomes the slot's first score: it is
  /// stored like a director's entry (attempt, official score, placeholder and
  /// the move of a `Ready` contest to `Running`, in one transaction) but with
  /// authority `Participant`, the guest as actor and the invitation as access
  /// reference. A director's later entry for the slot is a correction on top
  /// of it, so the director's value wins and the pilot's stays in the history.
  ///
  /// A repeat of [clientMutationId] with the same components returns the
  /// first answer ([ParticipantSubmission.replayed]); with other components
  /// it is a `mutation_conflict`. The recalculation and the publish that
  /// follow are the caller's.
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
    final slot = await _participantSlot(access, round);

    final earlier = await repository.scoreAttemptRepository
        .findByClientMutationId(contest.id, clientMutationId);
    if (earlier != null) {
      return _participantReplay(contest, context, slot, earlier, components);
    }

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

    final _Prepared prepared;
    try {
      prepared = await _prepare(
        contest,
        context,
        slot.assignment.id,
        clientMutationId: clientMutationId,
        baseScoreRevision: 0,
        components: components,
        reason: participantReason,
        actorId: access.guestAccountId,
        metadata: MutationMetadata(
          clientMutationId: clientMutationId,
          authority: Authority.participant,
          clientTime: _clock(),
          actorId: access.guestAccountId,
        ),
        moveContest: true,
        authority: Authority.participant,
        invitationId: access.invitation.id,
        sourceDevice: sourceDevice,
      );
    } on ScoringValidationError catch (error) {
      throw ParticipantSubmissionRefusal(
        400,
        'validation_failed',
        'the score has fields that are missing or not allowed',
        fieldErrors: _issueFieldErrors(error.issues),
      );
    }
    final recorded = await repository.officialScoreRepository.recordEntry(
      prepared.entry!,
      metadata: MutationMetadata(
        clientMutationId: clientMutationId,
        authority: Authority.participant,
        clientTime: _clock(),
        actorId: access.guestAccountId,
      ),
    );
    return ParticipantSubmission(
      assignmentId: slot.assignment.id,
      round: round,
      officialScore: recorded.officialScore,
      placeholder: recorded.placeholder,
      calculated: prepared.calculated!,
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

  /// The first answer to a mutation id that was stored before.
  Future<ParticipantSubmission> _participantReplay(
    Contest contest,
    _Configuration context,
    _Slot slot,
    ScoreAttempt earlier,
    Map<String, Object?> components,
  ) async {
    final official =
        (await repository.officialScoreRepository.listForPlaceholder(
          slot.placeholder.id,
        )).where((score) => score.scoreAttemptId == earlier.id).firstOrNull;
    if (earlier.scorePlaceholderId != slot.placeholder.id ||
        earlier.authority != Authority.participant ||
        official == null ||
        !_sameComponents(earlier.rawComponents, components)) {
      throw ParticipantSubmissionRefusal(
        409,
        'mutation_conflict',
        'this request id was already used for a different score',
      );
    }
    return ParticipantSubmission(
      assignmentId: slot.assignment.id,
      round: slot.round,
      officialScore: official,
      placeholder: slot.placeholder,
      calculated: await _calculate(context, official.components),
      authority: Authority.participant,
      replayed: true,
    );
  }

  /// The score now official on the slot, for `score_already_submitted`.
  Future<ParticipantSubmission> _accepted(
    _Configuration context,
    _Slot slot,
    int round,
  ) async {
    final official = (await repository.officialScoreRepository
        .currentForPlaceholder(slot.placeholder.id))!;
    final attempt = await repository.scoreAttemptRepository.findById(
      official.scoreAttemptId,
    );
    return ParticipantSubmission(
      assignmentId: slot.assignment.id,
      round: round,
      officialScore: official,
      placeholder: slot.placeholder,
      calculated: await _calculate(context, official.components),
      authority: attempt?.authority ?? Authority.director,
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
