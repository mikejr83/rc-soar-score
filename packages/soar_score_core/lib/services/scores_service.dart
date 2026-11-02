import 'package:logging/logging.dart';

import '../enums/admin_lock.dart';
import '../enums/authority.dart';
import '../enums/discipline_type.dart';
import '../enums/lifecycle_state.dart';
import '../enums/score_placeholder_state.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../errors/scoring_validation_error.dart';
import '../models/contest/contest.dart';
import '../models/contest/contest_configuration_revision.dart';
import '../models/id.dart';
import '../models/matrix/matrix_assignment.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/score_placeholder.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/recorded_score.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';
import '../scoring/f5j/f5j_profile.dart';
import 'bulk_score_entry.dart';
import 'calculated_flight.dart';
import 'contest_scores.dart';
import 'landing_bonus.dart';
import 'score_correction_audit.dart';
import 'score_entry_result.dart';
import 'score_history.dart';

final _logger = Logger('ScoresService');

/// Reads the scores of a contest and lets the director enter an official
/// score for a pilot in a group.
///
/// An entry stores the attempt (the raw components as the director gave
/// them), the official score taken from it and the placeholder in its new
/// state, in one transaction. The first accepted score also moves a `Ready`
/// contest to `Running`. Entering a score for a slot that already has one is
/// a correction: it adds the next score revision, keeps the earlier ones and
/// leaves a `ScoreAttempt` audit event naming the pilot and round, stored
/// with it (see `ScoreCorrectionAudit`). A first entry leaves none.
///
/// Only F5J is scored so far; the other disciplines follow the same path.
class ScoresService {
  ScoresService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  /// The reason stored with a first entry that gives none.
  static const String defaultReason = 'Entered by the director';

  final Repository repository;
  final F5jProfile _f5j = F5jProfile();
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Every score slot of the current matrix of contest [contestId], with the
  /// scored and total count of each round.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist. A
  /// contest that is not drawn yet has no slots.
  Future<ContestScores> list(Id contestId) async {
    await _requireContest(contestId);
    final rounds =
        (await repository.roundRepository.listForContest(contestId))
            .where((round) => round.isCurrent)
            .toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
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

    // The slots of a pilot who retired stay in the list; the counts leave out
    // the ones nobody can fill (see RoundProgress.count).
    final slots = <ScoreSlot>[];
    final progress = <RoundProgress>[];
    for (final round in rounds) {
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      );
      progress.add(
        RoundProgress.count(
          round,
          live,
          placeholders: placeholders,
          participations: participations,
        ),
      );
      for (final assignment in live) {
        final placeholder = placeholders[assignment.id];
        if (placeholder == null) continue;
        slots.add(
          ScoreSlot(
            placeholder: placeholder,
            officialScore: await repository.officialScoreRepository
                .currentForPlaceholder(placeholder.id),
          ),
        );
      }
    }
    return ContestScores(slots: slots, rounds: progress);
  }

  /// Every submission to the slot [assignmentId] of contest [contestId],
  /// oldest first: each official revision with its reason, who set it and
  /// when, and the attempts that never became official: a participant's
  /// entry that lost to the director's decision, or the newest one while the
  /// slot is still Submitted or InReview (pending).
  ///
  /// Throws an [EntityNotFoundError] for an unknown contest or slot. A slot
  /// that was moved keeps its history.
  Future<ScoreHistory> history(Id contestId, Id assignmentId) async {
    await _requireContest(contestId);
    final assignment = await repository.matrixAssignmentRepository.findById(
      assignmentId,
    );
    final placeholder = assignment == null || assignment.contestId != contestId
        ? null
        : await repository.scorePlaceholderRepository.findForAssignment(
            assignmentId,
          );
    if (placeholder == null) {
      throw EntityNotFoundError(
        entityType: 'MatrixAssignment',
        entityId: assignmentId,
      );
    }
    final attempts = await repository.scoreAttemptRepository.listForPlaceholder(
      placeholder.id,
    );
    final officials = {
      for (final score
          in await repository.officialScoreRepository.listForPlaceholder(
            placeholder.id,
          ))
        score.scoreAttemptId: score,
    };
    final awaiting =
        placeholder.state == ScorePlaceholderState.submitted ||
        placeholder.state == ScorePlaceholderState.inReview;
    final current = officials.values.fold<int>(
      0,
      (best, score) => score.scoreRevision > best ? score.scoreRevision : best,
    );
    return ScoreHistory(
      assignmentId: assignmentId,
      entries: [
        for (final (i, attempt) in attempts.indexed)
          if (officials[attempt.id] case final official?)
            ScoreHistoryEntry(
              attemptId: attempt.id,
              outcome: official.scoreRevision == current
                  ? ScoreHistoryOutcome.current
                  : ScoreHistoryOutcome.superseded,
              scoreRevision: official.scoreRevision,
              components: official.components,
              reason: official.reason,
              actorId: official.setBy,
              authority: attempt.authority,
              at: official.setAt,
            )
          else
            ScoreHistoryEntry(
              attemptId: attempt.id,
              // Only the newest attempt can still be waiting for a decision.
              outcome: awaiting && i == attempts.length - 1
                  ? ScoreHistoryOutcome.pending
                  : ScoreHistoryOutcome.notAdopted,
              components: attempt.rawComponents,
              actorId: attempt.actorId,
              authority: attempt.authority,
            ),
      ],
    );
  }

  /// Enters [components] as the official score of the slot [assignmentId].
  ///
  /// [baseScoreRevision] is the score revision the caller read from the
  /// slot's placeholder (0 for a slot with no score); a different stored
  /// revision is a [StaleRevisionError]. A repeated [clientMutationId]
  /// returns the entry it made the first time and stores nothing. A
  /// correction needs a [reason]; a first entry defaults to
  /// [defaultReason].
  ///
  /// Throws an [EntityNotFoundError] for an unknown contest or slot, a
  /// [ScoringValidationError] for components the discipline refuses, and a
  /// [ContestStateError] when the contest or slot cannot take a score.
  Future<ScoreEntryResult> enterOfficialScore(
    Id contestId,
    Id assignmentId, {
    required String clientMutationId,
    required int baseScoreRevision,
    required Map<String, Object?> components,
    String? reason,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final context = await _configuration(contest);
    final prepared = await _prepare(
      contest,
      context,
      assignmentId,
      clientMutationId: clientMutationId,
      baseScoreRevision: baseScoreRevision,
      components: components,
      reason: reason,
      actorId: actorId,
      metadata: metadata,
      moveContest: true,
    );
    final replay = prepared.replay;
    if (replay != null) return replay;
    final recorded = await repository.officialScoreRepository.recordEntry(
      prepared.entry!,
      metadata: metadata,
    );
    return ScoreEntryResult(
      officialScore: recorded.officialScore,
      placeholder: recorded.placeholder,
      contest: recorded.contest ?? contest,
      calculated: prepared.calculated!,
    );
  }

  /// Enters many scores at once, for the slots of one contest.
  ///
  /// Every entry is checked first, exactly as a single entry is (stale
  /// revision, locks, retired pilot, invalid components, a missing reason for
  /// a correction); an entry that fails is refused alone and the others go
  /// on. The accepted entries are stored together in ONE transaction. When
  /// that transaction is refused because a revision moved underneath it,
  /// nothing of it is kept and the entries are stored one by one instead, so
  /// only the entries that really conflict are refused, and an entry that
  /// fails otherwise is reported as failed (500) while the rest are kept.
  /// Any other failure of the single transaction is thrown with nothing
  /// stored. Repeating a request is safe because each entry keeps its
  /// [BulkScoreEntry.clientMutationId]; the contest start, the
  /// recalculation and the publish that follow run for a replay as well, so a
  /// request that stopped after storing its scores is finished by a repeat.
  ///
  /// Returns one outcome per entry, in order. The recalculation and the
  /// publish that follow are the caller's, and run once for the request.
  Future<List<BulkScoreOutcome>> enterOfficialScores(
    Id contestId,
    List<BulkScoreEntry> entries, {
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final context = await _configuration(contest);

    final outcomes = List<BulkScoreOutcome?>.filled(entries.length, null);
    final prepared = <int, _Prepared>{};
    final replays = <int, ScoreEntryResult>{};
    final seenSlots = <Id>{};
    final seenMutations = <String>{};
    int? round;
    for (final (i, entry) in entries.indexed) {
      if (!seenSlots.add(entry.assignmentId)) {
        outcomes[i] = const BulkScoreOutcome.refused(
          statusCode: 400,
          code: 'invalid_request',
          message: 'the request has two entries for the same slot',
        );
        continue;
      }
      if (!seenMutations.add(entry.clientMutationId)) {
        outcomes[i] = const BulkScoreOutcome.refused(
          statusCode: 400,
          code: 'invalid_request',
          message: 'the request uses one client mutation id twice',
        );
        continue;
      }
      try {
        final one = await _prepare(
          contest,
          context,
          entry.assignmentId,
          clientMutationId: entry.clientMutationId,
          baseScoreRevision: entry.baseScoreRevision,
          components: entry.components,
          reason: entry.reason,
          actorId: actorId,
          metadata: metadata.forPart(entry.clientMutationId),
          // The contest is started once, after the entries are stored, so
          // no entry can be refused because of a contest conflict.
          moveContest: false,
        );
        if (one.replay != null) {
          replays[i] = one.replay!;
        } else if (round != null && round != one.round) {
          outcomes[i] = const BulkScoreOutcome.refused(
            statusCode: 400,
            code: 'invalid_request',
            message: 'a bulk entry is for the slots of one round',
          );
        } else {
          round = one.round;
          prepared[i] = one;
        }
      } on Object catch (error) {
        final refused = _refusal(error);
        if (refused == null) rethrow;
        outcomes[i] = refused;
      }
    }

    final stored = <int, RecordedScore>{};
    if (prepared.isNotEmpty) {
      final order = prepared.keys.toList();
      List<RecordedScore>? recorded;
      try {
        recorded = await repository.officialScoreRepository.recordEntries([
          for (final i in order) prepared[i]!.entry!,
        ], metadata: metadata);
      } on StaleRevisionError {
        recorded = null;
      } on AlreadyStoredError {
        recorded = null;
      }
      if (recorded != null) {
        for (final (k, i) in order.indexed) {
          stored[i] = recorded[k];
        }
      } else {
        // A revision moved while the entries were being stored. Nothing was
        // kept, so store them one by one; only the real conflicts are
        // refused.
        for (final i in order) {
          try {
            stored[i] = await repository.officialScoreRepository.recordEntry(
              prepared[i]!.entry!,
              metadata: metadata.forPart(entries[i].clientMutationId),
            );
          } on Object catch (error, stackTrace) {
            // The entries before this one are already stored, so report
            // this one as failed and go on instead of throwing.
            final refused = _refusal(error);
            if (refused == null) {
              _logger.warning(
                'Bulk fallback: storing entry $i failed',
                error,
                stackTrace,
              );
            }
            outcomes[i] =
                refused ??
                const BulkScoreOutcome.refused(
                  statusCode: 500,
                  code: 'internal_error',
                  message: 'The entry could not be stored.',
                );
          }
        }
      }
    }

    if (stored.isNotEmpty || replays.isNotEmpty) {
      // A replay also starts the contest: an earlier request may have
      // stopped after storing its scores.
      final started = await _startContest(contest, metadata);
      for (final MapEntry(key: i, value: replay) in replays.entries) {
        outcomes[i] = BulkScoreOutcome.saved(
          ScoreEntryResult(
            officialScore: replay.officialScore,
            placeholder: replay.placeholder,
            contest: started,
            calculated: replay.calculated,
          ),
        );
      }
      for (final MapEntry(key: i, value: one) in stored.entries) {
        outcomes[i] = BulkScoreOutcome.saved(
          ScoreEntryResult(
            officialScore: one.officialScore,
            placeholder: one.placeholder,
            contest: started,
            calculated: prepared[i]!.calculated!,
          ),
        );
      }
    }
    return [for (final outcome in outcomes) outcome!];
  }

  /// Moves a `Ready` contest to `Running` after its first stored scores, and
  /// returns the contest as it is. A conflicting contest change is read
  /// again once; a contest that has moved on by itself is left alone.
  Future<Contest> _startContest(
    Contest contest,
    MutationMetadata metadata,
  ) async {
    var current = contest;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (current.lifecycleState != LifecycleState.ready) return current;
      try {
        return await repository.contestRepository.save(
          current.copyWithState(
            lifecycleState: LifecycleState.running,
            updatedAt: _clock(),
          ),
          metadata: metadata.forPart('contest-${current.id.value}'),
        );
      } on StaleRevisionError {
        current = await _requireContest(current.id);
      } on Object catch (error, stackTrace) {
        // The scores are stored; a repeat of the request starts the contest.
        _logger.warning(
          'Starting the contest after a bulk entry failed',
          error,
          stackTrace,
        );
        return current;
      }
    }
    return current;
  }

  /// The outcome that stands for [error] on one entry, or null when the
  /// error is not about the entry (it is the request's, and is thrown).
  BulkScoreOutcome? _refusal(Object error) => switch (error) {
    EntityNotFoundError() => BulkScoreOutcome.refused(
      statusCode: 404,
      code: 'not_found',
      message: '$error',
    ),
    ContestStateError(:final code, :final message) => BulkScoreOutcome.refused(
      statusCode: 409,
      code: code,
      message: message,
    ),
    StaleRevisionError() => BulkScoreOutcome.refused(
      statusCode: 409,
      code: 'stale_revision',
      message: '$error',
    ),
    AlreadyStoredError() => BulkScoreOutcome.refused(
      statusCode: 409,
      code: 'already_stored',
      message: '$error',
    ),
    ScoringValidationError() => BulkScoreOutcome.refused(
      statusCode: 400,
      code: 'invalid_request',
      message: '$error',
    ),
    ArgumentError(:final message) => BulkScoreOutcome.refused(
      statusCode: 400,
      code: 'invalid_request',
      message: '${message ?? error}',
    ),
    _ => null,
  };

  /// Checks one entry and builds what would be stored for it, or finds that
  /// it was entered before ([_Prepared.replay]). Stores nothing.
  Future<_Prepared> _prepare(
    Contest contest,
    _Configuration context,
    Id assignmentId, {
    required String clientMutationId,
    required int baseScoreRevision,
    required Map<String, Object?> components,
    required String? reason,
    required Id actorId,
    required MutationMetadata metadata,
    required bool moveContest,
  }) async {
    final contestId = contest.id;
    final earlier = await repository.scoreAttemptRepository
        .findByClientMutationId(contestId, clientMutationId);
    if (earlier != null) {
      return _Prepared.replay(
        await _replay(contest, context, earlier, assignmentId),
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
    if (placeholder.scoreRevision != baseScoreRevision) {
      throw StaleRevisionError(
        entityType: 'ScorePlaceholder',
        entityId: placeholder.id,
        expectedRevision: baseScoreRevision,
        storedRevision: placeholder.scoreRevision,
      );
    }
    final isCorrection = placeholder.scoreRevision > 0;
    final trimmed = reason?.trim();
    if (isCorrection && (trimmed == null || trimmed.isEmpty)) {
      throw ArgumentError('a reason is required to correct a score');
    }

    final calculated = await _calculate(context, components);
    final now = _clock();
    final attempt = ScoreAttempt(
      id: _newId(),
      contestId: contestId,
      scorePlaceholderId: placeholder.id,
      configRevisionId: context.revision.id,
      matrixRevisionId: slot.assignment.matrixRevisionId,
      rawComponents: components,
      actorId: actorId,
      authority: Authority.director,
      clientMutationId: clientMutationId,
      baseScoreRevision: baseScoreRevision,
    );
    final official = OfficialScore(
      id: _newId(),
      contestId: contestId,
      scorePlaceholderId: placeholder.id,
      scoreAttemptId: attempt.id,
      scoreRevision: baseScoreRevision + 1,
      components: components,
      setAt: now,
      setBy: actorId,
      reason: (trimmed == null || trimmed.isEmpty) ? defaultReason : trimmed,
    );
    final updated = ScorePlaceholder(
      id: placeholder.id,
      contestId: contestId,
      contestParticipationId: placeholder.contestParticipationId,
      assignmentId: placeholder.assignmentId,
      state: ScorePlaceholderState.official,
      scoreRevision: official.scoreRevision,
      lockedBy: placeholder.lockedBy,
      lockedAt: placeholder.lockedAt,
      revision: placeholder.revision,
    );
    final entry = RecordedScore(
      attempt: attempt,
      officialScore: official,
      placeholder: updated,
      contest: moveContest && contest.lifecycleState == LifecycleState.ready
          ? contest.copyWithState(
              lifecycleState: LifecycleState.running,
              updatedAt: now,
            )
          : null,
      audit: isCorrection
          ? ScoreCorrectionAudit.event(
              id: _newId(),
              attempt: attempt,
              official: official,
              previousRevision: baseScoreRevision,
              pilotNumber: slot.pilotNumber,
              round: slot.round,
              group: slot.assignment.group,
              previousPoints: await _previousPoints(context, placeholder),
              points: calculated.rawScore,
              metadata: metadata,
              at: now,
            )
          : null,
    );
    return _Prepared(entry, calculated, slot.round);
  }

  /// The points of the score now official on [placeholder], or null when they
  /// cannot be worked out any more (the configuration changed under them).
  Future<double?> _previousPoints(
    _Configuration context,
    ScorePlaceholder placeholder,
  ) async {
    final current = await repository.officialScoreRepository
        .currentForPlaceholder(placeholder.id);
    if (current == null) return null;
    try {
      return (await _calculate(context, current.components)).rawScore;
    } on ScoringValidationError {
      return null;
    }
  }

  Future<ScoreEntryResult> _replay(
    Contest contest,
    _Configuration context,
    ScoreAttempt earlier,
    Id assignmentId,
  ) async {
    final placeholder = await repository.scorePlaceholderRepository
        .findForAssignment(assignmentId);
    if (placeholder == null || placeholder.id != earlier.scorePlaceholderId) {
      throw AlreadyStoredError(
        entityType: 'ScoreAttempt',
        entityId: earlier.id,
      );
    }
    final official =
        (await repository.officialScoreRepository.listForPlaceholder(
          placeholder.id,
        )).where((score) => score.scoreAttemptId == earlier.id).firstOrNull;
    if (official == null) {
      throw AlreadyStoredError(
        entityType: 'ScoreAttempt',
        entityId: earlier.id,
      );
    }
    return ScoreEntryResult(
      officialScore: official,
      placeholder: placeholder,
      contest: contest,
      calculated: await _calculate(context, official.components),
    );
  }

  void _requireScoringAllowed(Contest contest) {
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'the contest is locked; unlock it to enter scores',
      );
    }
    if (contest.lifecycleState != LifecycleState.ready &&
        contest.lifecycleState != LifecycleState.running) {
      throw ContestStateError(
        'scoring_not_available',
        'scores can be entered once the matrix is drawn and until the '
            'contest is completed',
      );
    }
  }

  Future<_Slot> _requireSlot(Id contestId, Id assignmentId) async {
    final assignment = await repository.matrixAssignmentRepository.findById(
      assignmentId,
    );
    if (assignment == null || assignment.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'MatrixAssignment',
        entityId: assignmentId,
      );
    }
    if (assignment.isSuperseded) {
      throw ContestStateError(
        'assignment_superseded',
        'this assignment was moved; enter the score on the current one',
      );
    }
    final round = await repository.roundRepository.findById(
      assignment.scheduledRoundId,
    );
    if (round == null || !round.isCurrent) {
      throw ContestStateError(
        'round_not_current',
        'the assignment belongs to a round that is no longer current',
      );
    }
    final groups = await repository.roundGroupRepository.listForRound(round.id);
    if (groups.any((g) => g.groupNumber == assignment.group && g.isLocked)) {
      throw ContestStateError(
        'group_locked',
        'group ${assignment.group} is locked; unlock it first',
      );
    }
    final participation = await repository.contestParticipationRepository
        .findById(assignment.contestParticipationId);
    if (participation != null && participation.hasRetiredBy(round.ordinal)) {
      throw ContestStateError(
        'pilot_retired',
        'the pilot retired before this round',
      );
    }
    final placeholder = await repository.scorePlaceholderRepository
        .findForAssignment(assignmentId);
    if (placeholder == null) {
      throw EntityNotFoundError(
        entityType: 'ScorePlaceholder',
        entityId: assignmentId,
      );
    }
    return _Slot(
      assignment,
      placeholder,
      round: round.ordinal,
      pilotNumber: participation?.participantNumber,
    );
  }

  Future<_Configuration> _configuration(Contest contest) async {
    final revision = await repository.contestConfigurationRevisionRepository
        .latestForContest(contest.id);
    if (revision == null) {
      throw ContestStateError(
        'not_configured',
        'the contest has no configuration yet',
      );
    }
    final profile = await repository.disciplineProfileRepository.findById(
      revision.disciplineProfileId,
    );
    if (profile == null) {
      throw EntityNotFoundError(
        entityType: 'DisciplineProfile',
        entityId: revision.disciplineProfileId,
      );
    }
    if (profile.profile.type != DisciplineType.f5j) {
      throw ContestStateError(
        'discipline_not_supported',
        'score entry is not available for ${profile.profile.name} yet',
      );
    }
    return _Configuration(revision);
  }

  Future<CalculatedFlight> _calculate(
    _Configuration context,
    Map<String, Object?> components,
  ) async {
    final profile = _f5j;
    final options = context.revision.config.discipline;
    profile.validateOrThrow(components);
    final bonus = await resolveLandingBonus(
      repository,
      context.revision,
      components,
    );
    return CalculatedFlight.fromF5j(
      profile.calculate(components, overrides: options, landingBonus: bonus),
    );
  }

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }
}

class _Configuration {
  const _Configuration(this.revision);

  final ContestConfigurationRevision revision;
}

class _Prepared {
  const _Prepared(
    RecordedScore this.entry,
    CalculatedFlight this.calculated,
    int this.round,
  ) : replay = null;

  const _Prepared.replay(ScoreEntryResult this.replay)
    : entry = null,
      calculated = null,
      round = null;

  final RecordedScore? entry;
  final CalculatedFlight? calculated;

  /// The ordinal of the entry's round (null for a replay).
  final int? round;

  /// The result of the earlier entry with the same mutation id.
  final ScoreEntryResult? replay;
}

class _Slot {
  const _Slot(
    this.assignment,
    this.placeholder, {
    required this.round,
    this.pilotNumber,
  });

  final MatrixAssignment assignment;
  final ScorePlaceholder placeholder;

  /// The ordinal of the slot's round.
  final int round;

  final int? pilotNumber;
}
