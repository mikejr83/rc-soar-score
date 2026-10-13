import '../enums/admin_lock.dart';
import '../enums/authority.dart';
import '../enums/discipline_type.dart';
import '../enums/lifecycle_state.dart';
import '../enums/score_placeholder_state.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
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
import 'calculated_flight.dart';
import 'contest_scores.dart';
import 'landing_bonus.dart';
import 'score_entry_result.dart';

/// Reads the scores of a contest and lets the director enter an official
/// score for a pilot in a group.
///
/// An entry stores the attempt (the raw components as the director gave
/// them), the official score taken from it and the placeholder in its new
/// state, in one transaction. The first accepted score also moves a `Ready`
/// contest to `Running`. Entering a score for a slot that already has one is
/// a correction: it adds the next score revision and keeps the earlier ones.
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

    final earlier = await repository.scoreAttemptRepository
        .findByClientMutationId(contestId, clientMutationId);
    if (earlier != null) {
      return _replay(contest, context, earlier, assignmentId);
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
    final recorded = await repository.officialScoreRepository.recordEntry(
      RecordedScore(
        attempt: attempt,
        officialScore: official,
        placeholder: updated,
        contest: contest.lifecycleState == LifecycleState.ready
            ? contest.copyWithState(
                lifecycleState: LifecycleState.running,
                updatedAt: now,
              )
            : null,
      ),
      metadata: metadata,
    );
    return ScoreEntryResult(
      officialScore: recorded.officialScore,
      placeholder: recorded.placeholder,
      contest: recorded.contest ?? contest,
      calculated: calculated,
    );
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
    return _Slot(assignment, placeholder);
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
    final profile = F5jProfile();
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

class _Slot {
  const _Slot(this.assignment, this.placeholder);

  final MatrixAssignment assignment;
  final ScorePlaceholder placeholder;
}
