import 'dart:math';

import '../../enums/admin_lock.dart';
import '../../enums/assignment_type.dart';
import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/lifecycle_state.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../../models/contest/core_options.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../contest_scores.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/already_stored_error.dart';
import '../../repositories/finalized_draw.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/repository.dart';
import '../../enums/draw_mode.dart';
import 'basic_draw.dart';
import '../../models/matrix/current_matrix.dart';
import '../../models/matrix/matrix_revision.dart';
import 'draw_engine.dart';
import 'draw_job.dart';
import 'draw_optimizer.dart';
import 'matrix_draw_builder.dart';

/// The flight matrix operations of the API: reading the current matrix and
/// drawing it.
///
/// The draw is made by [DrawEngine]: every round is built several times and
/// the fairest build kept, the whole draw is improved across all rounds, and
/// that is repeated for several seeds, keeping the fairest result. Every draw
/// is finalized as it is made, so there is no draft stage yet.
class MatrixService {
  MatrixService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
    int Function()? newSeed,
    DrawRunner? runner,
    DrawJobs? jobs,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create,
       _newSeed = newSeed ?? secureSeed,
       _runner = runner ?? const InProcessDrawRunner(),
       jobs = jobs ?? DrawJobs();

  /// Names the draw engine on every revision. A change to how pilots are
  /// dealt needs a new version, so an old draw can still be reproduced.
  static const String algorithmVersion = DrawEngine.algorithmVersion;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;
  final int Function() _newSeed;
  final DrawRunner _runner;

  /// The draws running or lately run, by revision id: how far each has come,
  /// and the way to cancel one.
  final DrawJobs jobs;

  /// A fresh 32-bit seed for a draw that was not given one.
  static int secureSeed() => Random.secure().nextInt(0x100000000);

  /// The current matrix of contest [contestId]; empty before the first draw.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist.
  Future<CurrentMatrix> current(Id contestId) async {
    await _requireContest(contestId);
    final revisions = repository.matrixRevisionRepository;
    final all = await revisions.listForContest(contestId);
    final finalized = all.where((revision) => revision.isFinalized).toList();
    if (finalized.isEmpty) {
      return CurrentMatrix();
    }
    final rounds = (await repository.roundRepository.listForContest(contestId))
        .where((round) => round.isCurrent)
        .toList();
    final roundIds = {for (final round in rounds) round.id};
    final groups = (await repository.roundGroupRepository.listForContest(
      contestId,
    )).where((group) => roundIds.contains(group.roundId));
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
    final assignments = <MatrixAssignment>[];
    final progress = <RoundProgress>[];
    for (final round in rounds) {
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      );
      assignments.addAll(live);
      progress.add(
        RoundProgress.count(
          round,
          live,
          placeholders: placeholders,
          participations: participations,
        ),
      );
    }
    return CurrentMatrix(
      revision: finalized.last,
      rounds: rounds,
      groups: groups,
      assignments: assignments,
      progress: progress,
    );
  }

  /// Every matrix revision of contest [contestId], newest first; empty before
  /// the first draw.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist.
  Future<List<MatrixRevision>> revisions(Id contestId) async {
    await _requireContest(contestId);
    final all = await repository.matrixRevisionRepository.listForContest(
      contestId,
    );
    return all.reversed.toList();
  }

  /// One stored matrix revision with its rounds, groups and the assignments
  /// the draw made — its `Original` rows. A read-only history view: it shows
  /// the revision exactly as drawn, so it shows no progress and drops the
  /// moves, re-flights and late adds made after the draw; a pilot that was
  /// later moved still appears in the group the draw placed them in.
  ///
  /// Throws an [EntityNotFoundError] when the contest or the revision does
  /// not exist, or the revision belongs to a different contest.
  Future<CurrentMatrix> revision(Id contestId, Id revisionId) async {
    await _requireContest(contestId);
    final revision = await repository.matrixRevisionRepository.findById(
      revisionId,
    );
    if (revision == null || revision.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'MatrixRevision',
        entityId: revisionId,
      );
    }
    final rounds = await repository.roundRepository.listForRevision(revisionId);
    final roundIds = {for (final round in rounds) round.id};
    final groups = (await repository.roundGroupRepository.listForContest(
      contestId,
    )).where((group) => roundIds.contains(group.roundId));
    final assignments =
        (await repository.matrixAssignmentRepository.listForRevision(
              revisionId,
            ))
            .where(
              (assignment) =>
                  assignment.assignmentType == AssignmentType.original,
            )
            .toList();
    return CurrentMatrix(
      revision: revision,
      rounds: rounds,
      groups: groups,
      assignments: assignments,
    );
  }

  /// Draws the first matrix of contest [contestId] and finalizes it: [rounds]
  /// rounds of [groupsPerRound] groups each, as revision [id].
  ///
  /// Idempotent on [id]: repeating a draw returns the matrix it made. The
  /// [randomSeed] (32-bit unsigned) makes the draw reproducible; one is
  /// generated when null. Each round is built [attemptsPerRound] times and the
  /// build where pilots meet again least is kept, the whole draw is improved
  /// across all rounds, and that is done for [seedCount] seeds, keeping the
  /// fairest result; the revision stores the winning seed. Every pilot without a retirement is drawn, in
  /// every round. The draw gives each participation without one a participant
  /// number (one running sequence, in the order they were added), creates a
  /// score placeholder for every assignment, and moves the contest from
  /// `Configuring` to `Ready`.
  ///
  /// Throws:
  /// - `DrawCancelledError` when the draw was cancelled through [jobs];
  /// - `EntityNotFoundError` for an unknown contest;
  /// - `AlreadyStoredError` when [id] belongs to another contest's revision;
  /// - `ContestStateError` when the contest is not `Configuring` (a first
  ///   draw needs a saved configuration, and a matrix already exists
  ///   afterward), is locked, or uses a draw mode this draw does not support;
  /// - `ArgumentError` when the settings cannot be met: no pilots, [rounds]
  ///   below 1, [attemptsPerRound] outside 1 to 200, [seedCount] outside 1 to 20, [groupsPerRound] outside 1 to the number of pilots, or fewer
  ///   groups than the largest team under team protection.
  Future<CurrentMatrix> drawFirst(
    Id contestId, {
    required Id id,
    required int rounds,
    required int groupsPerRound,
    int? randomSeed,
    int attemptsPerRound = BasicDraw.defaultAttemptsPerRound,
    int seedCount = DrawEngine.defaultSeedCount,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final stored = await repository.matrixRevisionRepository.findById(id);
    if (stored != null) {
      if (stored.contestId != contestId) {
        throw AlreadyStoredError(entityType: 'MatrixRevision', entityId: id);
      }
      return current(contestId);
    }
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'the contest is locked; unlock it to draw the matrix',
      );
    }
    if (contest.lifecycleState != LifecycleState.configuring) {
      throw ContestStateError(
        contest.lifecycleState == LifecycleState.created
            ? 'not_configured'
            : 'matrix_exists',
        contest.lifecycleState == LifecycleState.created
            ? 'save the contest configuration before drawing the matrix'
            : 'the contest already has a matrix; a first draw needs a '
                  'Configuring contest',
      );
    }
    final configuration = await repository
        .contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (configuration == null) {
      throw ContestStateError(
        'not_configured',
        'save the contest configuration before drawing the matrix',
      );
    }
    final CoreOptions options = configuration.config.coreOptions;
    // A seeded contest draws its preliminary rounds like a standard one; the
    // seeded rounds follow once those are scored (see MatrixRedrawService).
    final preliminaryRounds = options.preliminaryRounds ?? 1;
    if (options.drawMode == DrawMode.seededManOnMan &&
        rounds > preliminaryRounds) {
      throw ContestStateError(
        'seeded_rounds_need_standings',
        'a seeded contest draws only its $preliminaryRounds preliminary '
            'round${preliminaryRounds == 1 ? '' : 's'} first; the seeded '
            'rounds are drawn after the preliminary scores are complete',
      );
    }

    final participations = await repository.contestParticipationRepository
        .listForContest(contestId);
    final teamOf = options.teamsEnabled
        ? {
            for (final membership
                in await repository.teamMembershipRepository.listForContest(
                  contestId,
                ))
              membership.contestParticipationId: membership.teamId,
          }
        : const <Id, Id>{};
    final pilots = [
      for (final p in participations)
        if (p.isPilot && !p.isRetired) DrawPilot(p.id, teamId: teamOf[p.id]),
    ];
    if (pilots.isEmpty) {
      throw ArgumentError('the contest has no pilots to draw');
    }

    final requestedSeed = randomSeed ?? _newSeed();
    // The draw is made before anything is stored, so a cancelled draw leaves
    // the contest as it was.
    final drawn = await jobs.run(
      contestId,
      id,
      _runner,
      DrawSpec(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: options.teamProtection,
        laneMode: options.laneMode,
        allowBackToBack: options.allowBackToBack,
        seed: requestedSeed,
        seedCount: seedCount,
        attemptsPerRound: attemptsPerRound,
      ),
    );

    final now = _clock();
    final finalized = _build(
      contest: contest,
      participations: participations,
      pilots: pilots,
      drawn: drawn,
      id: id,
      groupsPerRound: groupsPerRound,
      attemptsPerRound: attemptsPerRound,
      seedCount: seedCount,
      requestedSeed: requestedSeed,
      options: options,
      actorId: actorId,
      now: now,
    );
    final revision = finalized.draw.revision;
    final audit = AuditEvent(
      id: _newId(),
      entityType: revision.entityType,
      entityId: revision.id,
      contestId: contestId,
      action: AuditAction.matrixDrawn,
      actorId: metadata.actorId,
      authority: metadata.authority,
      installationId: metadata.sourceInstallationId,
      device: metadata.sourceDevice,
      resultingRevision: revision.revisionNumber,
      serverTimestamp: now,
      clientTimestamp: metadata.clientTime,
      reason: revision.reason,
      outcome: AuditOutcome.success,
    );
    await repository.matrixRevisionRepository.appendFinalizedDraw(
      finalized,
      metadata: metadata,
      audit: audit,
    );
    return current(contestId);
  }

  FinalizedDraw _build({
    required Contest contest,
    required List<ContestParticipation> participations,
    required List<DrawPilot> pilots,
    required DrawResult drawn,
    required Id id,
    required int groupsPerRound,
    required int attemptsPerRound,
    required int seedCount,
    required int requestedSeed,
    required CoreOptions options,
    required Id actorId,
    required DateTime now,
  }) {
    final built = MatrixDrawBuilder(newId: _newId).build(
      contestId: contest.id,
      id: id,
      revisionNumber: 1,
      firstRound: 1,
      drawn: drawn.rounds,
      seed: drawn.seed,
      algorithmVersion: algorithmVersion,
      groupsPerRound: groupsPerRound,
      drawConfig: {
        'schema_version': 1,
        'attempts_per_round': attemptsPerRound,
        'seed_count': seedCount,
        'requested_seed': requestedSeed,
        'iterations_per_placement': DrawOptimizer.defaultIterationsPerPlacement,
        'team_protection': options.teamProtection,
        'allow_back_to_back': options.allowBackToBack,
        'lane_mode': options.laneMode.json,
        'configured_draw_mode': options.drawMode.json,
      },
      pilots: pilots,
      fairness: drawn.fairness,
      reason: 'initial draw',
      actorId: actorId,
      now: now,
    );
    return FinalizedDraw(
      draw: built.draw,
      placeholders: built.placeholders,
      numberedParticipations: MatrixDrawBuilder.numbered(participations),
      contest: contest.copyWithState(
        lifecycleState: LifecycleState.ready,
        updatedAt: now,
      ),
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
