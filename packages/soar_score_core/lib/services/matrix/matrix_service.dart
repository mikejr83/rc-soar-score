import 'dart:math';

import '../../enums/admin_lock.dart';
import '../../enums/assignment_type.dart';
import '../../enums/lifecycle_state.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../../models/contest/core_options.dart';
import '../../models/id.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/matrix_draw.dart';
import '../../models/matrix/matrix_revision.dart';
import '../../models/matrix/round.dart';
import '../../models/matrix/round_group.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/score_placeholder.dart';
import '../../repositories/already_stored_error.dart';
import '../../repositories/finalized_draw.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/repository.dart';
import '../../enums/draw_mode.dart';
import 'basic_draw.dart';
import '../../models/matrix/current_matrix.dart';
import 'draw_fairness.dart';
import 'seeded_random.dart';

/// The flight matrix operations of the API: reading the current matrix and
/// drawing it.
///
/// The draw is the basic one (`BasicDraw`); the optimizer replaces the
/// dealing later. Every draw is finalized as it is made, so there is no
/// draft stage yet.
class MatrixService {
  MatrixService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
    int Function()? newSeed,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create,
       _newSeed = newSeed ?? _secureSeed;

  /// Names the draw engine on every revision. A change to how pilots are
  /// dealt needs a new version, so an old draw can still be reproduced.
  static const String algorithmVersion = 'basic-1';

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;
  final int Function() _newSeed;

  static int _secureSeed() => Random.secure().nextInt(0x100000000);

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
    final assignments = <MatrixAssignment>[];
    for (final round in rounds) {
      assignments.addAll(
        await repository.matrixAssignmentRepository.listLiveForRound(round.id),
      );
    }
    return CurrentMatrix(
      revision: finalized.last,
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
  /// generated when null. Every pilot without a retirement is drawn, in
  /// every round. The draw gives each participation without one a participant
  /// number (one running sequence, in the order they were added), creates a
  /// score placeholder for every assignment, and moves the contest from
  /// `Configuring` to `Ready`.
  ///
  /// Throws:
  /// - `EntityNotFoundError` for an unknown contest;
  /// - `AlreadyStoredError` when [id] belongs to another contest's revision;
  /// - `ContestStateError` when the contest is not `Configuring` (a first
  ///   draw needs a saved configuration, and a matrix already exists
  ///   afterward), is locked, or uses a draw mode this draw does not support;
  /// - `ArgumentError` when the settings cannot be met: no pilots, [rounds]
  ///   below 1, [groupsPerRound] outside 1 to the number of pilots, or fewer
  ///   groups than the largest team under team protection.
  Future<CurrentMatrix> drawFirst(
    Id contestId, {
    required Id id,
    required int rounds,
    required int groupsPerRound,
    int? randomSeed,
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
    if (options.drawMode != DrawMode.standardManOnMan) {
      throw ContestStateError(
        'draw_mode_unsupported',
        'only the standard man-on-man draw is available so far',
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

    final seed = randomSeed ?? _newSeed();
    final drawn = const BasicDraw().generate(
      pilots: pilots,
      rounds: rounds,
      groupsPerRound: groupsPerRound,
      teamProtection: options.teamProtection,
      laneMode: options.laneMode,
      random: SeededRandom(seed),
    );

    final now = _clock();
    final finalized = _build(
      contest: contest,
      participations: participations,
      pilots: pilots,
      drawn: drawn,
      id: id,
      groupsPerRound: groupsPerRound,
      seed: seed,
      options: options,
      actorId: actorId,
      now: now,
    );
    await repository.matrixRevisionRepository.appendFinalizedDraw(
      finalized,
      metadata: metadata,
    );
    return current(contestId);
  }

  FinalizedDraw _build({
    required Contest contest,
    required List<ContestParticipation> participations,
    required List<DrawPilot> pilots,
    required List<List<List<DrawSlot>>> drawn,
    required Id id,
    required int groupsPerRound,
    required int seed,
    required CoreOptions options,
    required Id actorId,
    required DateTime now,
  }) {
    final revision = MatrixRevision(
      id: id,
      contestId: contest.id,
      revisionNumber: 1,
      firstRound: 1,
      lastRound: drawn.length,
      drawMode: DrawMode.standardManOnMan,
      randomSeed: seed,
      algorithmVersion: algorithmVersion,
      drawConfig: {
        'schema_version': 1,
        'groups_per_round': groupsPerRound,
        'team_protection': options.teamProtection,
        'lane_mode': options.laneMode.json,
        'configured_draw_mode': options.drawMode.json,
      },
      seedingSnapshot: {
        'pilots': [
          for (final pilot in pilots)
            {
              'participation_id': pilot.participationId.value,
              'team_id': pilot.teamId?.value,
            },
        ],
      },
      fairnessSummary: drawFairness(drawn),
      reason: 'initial draw',
      createdBy: actorId,
      createdAt: now,
      finalizedBy: actorId,
      finalizedAt: now,
    );

    final rounds = <Round>[];
    final groups = <RoundGroup>[];
    final assignments = <MatrixAssignment>[];
    final placeholders = <ScorePlaceholder>[];
    for (var r = 0; r < drawn.length; r++) {
      final round = Round(
        id: _newId(),
        contestId: contest.id,
        matrixRevisionId: id,
        ordinal: r + 1,
        groupCount: groupsPerRound,
      );
      rounds.add(round);
      for (var g = 0; g < drawn[r].length; g++) {
        groups.add(
          RoundGroup(
            id: _newId(),
            contestId: contest.id,
            roundId: round.id,
            groupNumber: g + 1,
          ),
        );
        for (final slot in drawn[r][g]) {
          final assignment = MatrixAssignment(
            id: _newId(),
            contestId: contest.id,
            matrixRevisionId: id,
            contestParticipationId: slot.pilot.participationId,
            scheduledRoundId: round.id,
            creditedRoundId: round.id,
            group: g + 1,
            lane: slot.lane,
            assignmentType: AssignmentType.original,
            actorId: actorId,
            createdAt: now,
          );
          assignments.add(assignment);
          placeholders.add(
            ScorePlaceholder(
              id: _newId(),
              contestId: contest.id,
              contestParticipationId: slot.pilot.participationId,
              assignmentId: assignment.id,
            ),
          );
        }
      }
    }

    var next =
        participations.fold<int>(
          0,
          (highest, p) => max(highest, p.participantNumber ?? 0),
        ) +
        1;
    final numbered = [
      for (final p in participations)
        if (p.participantNumber == null) p.withParticipantNumber(next++),
    ];

    return FinalizedDraw(
      draw: MatrixDraw(
        revision: revision,
        rounds: rounds,
        groups: groups,
        assignments: assignments,
      ),
      placeholders: placeholders,
      numberedParticipations: numbered,
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
