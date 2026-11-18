part of 'scores_service.dart';

/// What one run of the automatic officialization made official.
class AutomaticOfficialization extends Equatable {
  const AutomaticOfficialization({
    this.promoted = const [],
    this.revisions = const {},
    this.heldForReview = 0,
  });

  /// No change.
  static const none = AutomaticOfficialization();

  /// The slots whose submission became official, in the order they were
  /// stored.
  final List<Id> promoted;

  /// The official score revision stored for each promoted slot.
  final Map<Id, int> revisions;

  /// Submissions of complete rounds or groups that stay waiting because an
  /// open review holds them.
  final int heldForReview;

  bool get changedScores => promoted.isNotEmpty;

  @override
  List<Object?> get props => [promoted, revisions, heldForReview];
}

/// The contest's own acceptance of participant submissions, by the setting
/// "Scores become official" (`end of round`, `end of group` or `manually`).
extension AutomaticOfficializationService on ScoresService {
  /// Makes the stored participant submissions official where the contest's
  /// policy says they are due, as the system (selection origin `Automatic`,
  /// no setter), and returns what it stored.
  ///
  /// A round (or group) is due when every slot nobody is excused from has a
  /// score, by the same count the progress cards use (`RoundProgress`): a
  /// submitted, in-review or official slot is entered, a missing score is
  /// never a zero, and a pilot who retired without a score is not waited
  /// for. A due round or group makes official the submissions of its slots
  /// that are `Submitted`. A slot with an open review (`InReview`) is held:
  /// it is never superseded and its proposal is never applied, and the other
  /// slots of the round are accepted without it. Locked rounds, groups and
  /// slots are left as they are, and so is a contest that takes no scores or
  /// has the policy `Manual`.
  ///
  /// The run is safe to repeat: it only turns `Submitted` slots into
  /// `Official` ones, each stored on its own with an operation id built from
  /// the slot, its score revision and the policy, so a second run, or a run
  /// that raced a writer outside the gate (an accepted sync change), finds
  /// nothing left to do or skips the slot that moved. It makes no
  /// recalculation or publication; the caller does that once for the batch
  /// when [AutomaticOfficialization.changedScores].
  ///
  /// An installation whose contest syncs (its [PromotionIntentPolicy] queues
  /// promotions) accepts nothing: the service decides, on its own submissions
  /// and accepted syncs, and its acceptances reach the installation in a pull
  /// like any adoption. A service that does not know the capability is
  /// therefore never written to either.
  ///
  /// It takes the contest's score gate; a [ContestBusyError] from it is
  /// thrown to the caller.
  Future<AutomaticOfficialization> evaluateAutomaticOfficialization(
    Id contestId,
  ) => repository.officialScoreRepository.withContestGate(
    contestId,
    () => _evaluateAutomaticOfficialization(contestId),
  );

  /// As [evaluateAutomaticOfficialization], and when it made scores official
  /// the results are recalculated in the same gated transaction, so the
  /// acceptances and the standings commit together or not at all.
  ///
  /// A failure of the recalculation (or of any acceptance) rolls the whole
  /// run back; nothing is half accepted and no standing is left behind the
  /// official scores. Run inside an outer gated transaction it is a
  /// savepoint of it, so the caller can keep its own writes. Because the gate
  /// is held from the read of the scores to the replacement of the results,
  /// two runs cannot interleave and overwrite newer standings.
  Future<AutomaticOfficialization> officializeAndRecalculate(Id contestId) =>
      repository.officialScoreRepository.withContestGate(contestId, () async {
        final run = await _evaluateAutomaticOfficialization(contestId);
        if (run.changedScores) {
          await ResultsService(
            repository,
            clock: _clock,
            newId: _newId,
          ).recalculate(contestId);
        }
        return run;
      });

  /// Repeats the automatic officialization for every contest that may owe
  /// one, and returns how many contests it made scores official in.
  ///
  /// The server runs it once when it starts: an evaluation that a restart
  /// (or a failure after the triggering change committed) interrupted is
  /// found again from the stored state. A contest owes one when it has a
  /// `Submitted` slot whose submission arrived on this server, that is,
  /// after the contest was first uploaded to it. A submission stored before
  /// that came with the upload (an RCSS import's pending scores, or history
  /// entered offline): it stays pending until a later trigger, so a restart
  /// never accepts it. A contest created on the server has no upload and
  /// every submission counts.
  ///
  /// This reads the policy and the stored scores, not a stored request, so a
  /// policy change interrupted before it ran is recovered only for
  /// submissions that arrived here. A run only turns `Submitted` slots into
  /// `Official` ones with a fixed operation id, so repeating it never creates
  /// a second official version. A contest that is busy or whose evaluation
  /// fails is logged and left for the next trigger; it never stops the
  /// others.
  Future<int> recoverAutomaticOfficialization() async {
    var changed = 0;
    for (final contest in await repository.contestRepository.getAll()) {
      if (contest.adminLock == AdminLock.locked ||
          (contest.lifecycleState != LifecycleState.ready &&
              contest.lifecycleState != LifecycleState.running)) {
        continue;
      }
      try {
        if (!await _owesEvaluation(contest.id)) continue;
        final run = await officializeAndRecalculate(contest.id);
        if (run.changedScores) changed++;
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Recovering automatic officialization failed for contest '
          '${contest.id}; it repeats on the next trigger',
          error,
          stackTrace,
        );
      }
    }
    return changed;
  }

  /// Whether [contestId] has a waiting submission that arrived on this server.
  Future<bool> _owesEvaluation(Id contestId) async {
    final waiting = [
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        if (placeholder.state == ScorePlaceholderState.submitted &&
            placeholder.currentAttemptId != null)
          placeholder.currentAttemptId!,
    ];
    if (waiting.isEmpty) return false;
    final activations = await repository.installationActivationRepository
        .listForContest(contestId);
    if (activations.isEmpty) return true;
    final uploaded = activations
        .map((activation) => activation.activatedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final attempts = await repository.scoreAttemptRepository.findByIds(waiting);
    return attempts.values.any(
      (attempt) => attempt.acceptedAt.isAfter(uploaded),
    );
  }

  Future<AutomaticOfficialization> _evaluateAutomaticOfficialization(
    Id contestId,
  ) async {
    // A contest that syncs is decided by the service: an acceptance made
    // here would travel as a generic director-wins write, so this
    // installation leaves the submissions waiting and the service's
    // acceptance arrives in a pull as one atomic change.
    if (await _promotionIntents.queuesPromotions(contestId)) {
      return AutomaticOfficialization.none;
    }
    final contest = await _requireContest(contestId);
    if (contest.adminLock == AdminLock.locked ||
        (contest.lifecycleState != LifecycleState.ready &&
            contest.lifecycleState != LifecycleState.running)) {
      return AutomaticOfficialization.none;
    }
    final _Configuration context;
    try {
      context = await _configuration(contest);
    } on ContestStateError {
      return AutomaticOfficialization.none;
    }
    final mode = context.revision.config.coreOptions.scoresBecomeOfficial;
    if (mode == OfficializationMode.manual) {
      return AutomaticOfficialization.none;
    }

    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.assignmentId: placeholder,
    };
    final participations = {
      for (final participation
          in await repository.contestParticipationRepository.listForContest(
            contestId,
          ))
        participation.id: participation,
    };
    final reviewed = {
      for (final review
          in await repository.reviewRequestRepository.listForContest(contestId))
        if (review.isOpen) review.scorePlaceholderId,
    };

    final promoted = <Id>[];
    final revisions = <Id, int>{};
    var held = 0;
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where(
              (round) => round.isCurrent && round.status != RoundStatus.locked,
            )
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    for (final round in rounds) {
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      );
      final lockedGroups = {
        for (final group in await repository.roundGroupRepository.listForRound(
          round.id,
        ))
          if (group.isLocked) group.groupNumber,
      };
      // The unit that has to be complete: the whole round, or one group.
      final units = mode == OfficializationMode.endOfRound
          ? [live]
          : [
              for (final number in {
                for (final a in live) a.group,
              }.toList()..sort())
                [
                  for (final a in live)
                    if (a.group == number) a,
                ],
            ];
      final reason = mode == OfficializationMode.endOfRound
          ? automaticRoundCompleteReason
          : automaticGroupCompleteReason;
      for (final unit in units) {
        final progress = RoundProgress.count(
          round,
          unit,
          placeholders: placeholders,
          participations: participations,
        );
        if (!progress.isComplete) continue;
        for (final assignment in unit) {
          final placeholder = placeholders[assignment.id];
          if (placeholder == null ||
              placeholder.state != ScorePlaceholderState.submitted &&
                  placeholder.state != ScorePlaceholderState.inReview) {
            continue;
          }
          if (reviewed.contains(placeholder.id) ||
              placeholder.state == ScorePlaceholderState.inReview) {
            held++;
            continue;
          }
          // A pilot who retired after submitting keeps the submission: the
          // retirement only excuses a missing score (see RoundProgress).
          if (placeholder.isLocked || lockedGroups.contains(assignment.group)) {
            continue;
          }
          final revision = await _promoteAutomatically(
            context,
            contest,
            placeholder,
            mode: mode,
            reason: reason,
          );
          if (revision != null) {
            promoted.add(assignment.id);
            revisions[assignment.id] = revision;
          }
        }
      }
    }
    return AutomaticOfficialization(
      promoted: promoted,
      revisions: revisions,
      heldForReview: held,
    );
  }

  /// Stores the automatic adoption of the submission waiting on [placeholder].
  /// Returns the stored official score revision, or null when the slot moved under it or its values are refused,
  /// which leaves it waiting for the next run.
  Future<int?> _promoteAutomatically(
    _Configuration context,
    Contest contest,
    ScorePlaceholder placeholder, {
    required OfficializationMode mode,
    required String reason,
  }) async {
    final attemptId = placeholder.currentAttemptId;
    final attempt = attemptId == null
        ? null
        : await repository.scoreAttemptRepository.findById(attemptId);
    if (attempt == null || attempt.scorePlaceholderId != placeholder.id) {
      return null;
    }
    try {
      await _calculate(context, attempt.rawComponents);
    } on ScoringValidationError catch (error) {
      _logger.warning(
        'Submission ${attempt.id} of contest ${contest.id} was not made '
        'official automatically: ${error.issues.length} refused field(s)',
      );
      return null;
    }
    final now = _clock();
    final official = OfficialScore(
      id: _newId(),
      contestId: contest.id,
      scorePlaceholderId: placeholder.id,
      scoreAttemptId: attempt.id,
      scoreRevision: placeholder.scoreRevision + 1,
      components: attempt.rawComponents,
      setAt: now,
      setBy: null,
      reason: reason,
      selectionOrigin: SelectionOrigin.automatic,
    );
    final updated = ScorePlaceholder(
      id: placeholder.id,
      contestId: contest.id,
      contestParticipationId: placeholder.contestParticipationId,
      assignmentId: placeholder.assignmentId,
      state: ScorePlaceholderState.official,
      scoreRevision: official.scoreRevision,
      currentAttemptId: attempt.id,
      lockedBy: placeholder.lockedBy,
      lockedAt: placeholder.lockedAt,
      revision: placeholder.revision,
    );
    try {
      await repository.officialScoreRepository.recordPromotion(
        PromotedScore(officialScore: official, placeholder: updated),
        metadata: MutationMetadata(
          clientMutationId:
              'automatic/${placeholder.id.value}/${placeholder.scoreRevision}/'
              '${mode.json}',
          authority: Authority.system,
          clientTime: now,
        ),
      );
    } on StaleRevisionError {
      return null;
    }
    return official.scoreRevision;
  }
}
