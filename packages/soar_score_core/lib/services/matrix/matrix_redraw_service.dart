import '../../enums/admin_lock.dart';
import '../../enums/assignment_type.dart';
import '../../enums/draw_mode.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/round_status.dart';
import '../../enums/score_placeholder_state.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../models/contest/contest.dart';
import '../contest_results.dart';
import '../../models/id.dart';
import '../../models/matrix/current_matrix.dart';
import '../../models/matrix/matrix_assignment.dart';
import '../../models/matrix/round.dart';
import '../../models/participants/contest_participation.dart';
import '../../repositories/already_stored_error.dart';
import '../../repositories/finalized_redraw.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/repository.dart';
import '../results_service.dart';
import 'basic_draw.dart';
import 'draw_engine.dart';
import 'draw_job.dart';
import 'draw_optimizer.dart';
import 'matrix_draw_builder.dart';
import 'matrix_service.dart';

/// Adds rounds to the matrix, or draws its unscored tail again.
///
/// In a `SeededManOnMan` contest the rounds up to `preliminary_rounds` are
/// drawn as above; each later round is seeded by the standings after the
/// round before it (leaders in the last group) and is drawn only once every
/// score before it is official and the standings are current.
///
/// Both are a new matrix revision that continues the rounds before it: pilots
/// who already met are kept apart as they are in the first draw, and the
/// fairness report covers every round. A redraw replaces every round from
/// [redraw]'s `firstRound` to the end of the contest, which is only allowed
/// while none of them has a score; an extension has `firstRound` one past the
/// last round. See `plan/data-model/entities/matrix_revision.md`.
class MatrixRedrawService {
  MatrixRedrawService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
    int Function()? newSeed,
    DrawRunner? runner,
    DrawJobs? jobs,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create,
       _newSeed = newSeed ?? MatrixService.secureSeed,
       _runner = runner ?? const InProcessDrawRunner(),
       jobs = jobs ?? DrawJobs();

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;
  final int Function() _newSeed;
  final DrawRunner _runner;

  /// The draws running or lately run, by revision id (see
  /// [MatrixService.jobs]).
  final DrawJobs jobs;

  /// Draws [rounds] rounds of [groupsPerRound] groups each from round
  /// [firstRound] on, as revision [id], and returns the current matrix.
  ///
  /// With [firstRound] one past the last round the matrix is extended. With
  /// [firstRound] at or before the last round, every round from there on is
  /// replaced: a round that has a new counterpart is superseded by it, and a
  /// round beyond the new last round is cancelled. Pilots without a
  /// retirement are drawn; the rounds before [firstRound] stay as they are and
  /// count toward who has met whom.
  ///
  /// Idempotent on [id]. [randomSeed], [attemptsPerRound] and [seedCount]
  /// are as in [MatrixService.drawFirst]. [reason] names the revision (a
  /// default is written when null).
  ///
  /// Throws:
  /// - `EntityNotFoundError` for an unknown contest;
  /// - `AlreadyStoredError` when [id] belongs to another contest;
  /// - `ContestStateError` when the contest has no matrix, is locked, is not
  ///   `Ready` or `Running`, uses an unsupported draw mode, or a round to
  ///   replace has a score or a locked group;
  /// - `ArgumentError` when [firstRound] is outside 1 to one past the last
  ///   round, or the draw settings cannot be met.
  Future<CurrentMatrix> redraw(
    Id contestId, {
    required Id id,
    required int firstRound,
    required int rounds,
    required int groupsPerRound,
    int? randomSeed,
    int attemptsPerRound = BasicDraw.defaultAttemptsPerRound,
    int seedCount = DrawEngine.defaultSeedCount,
    String? reason,
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final stored = await repository.matrixRevisionRepository.findById(id);
    if (stored != null) {
      if (stored.contestId != contestId) {
        throw AlreadyStoredError(entityType: 'MatrixRevision', entityId: id);
      }
      return MatrixService(repository).current(contestId);
    }
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'contest_locked',
        'the contest is locked; unlock it to draw rounds',
      );
    }
    if (contest.lifecycleState != LifecycleState.ready &&
        contest.lifecycleState != LifecycleState.running) {
      throw ContestStateError(
        'matrix_not_editable',
        'rounds can be added or redrawn once the first matrix is drawn and '
            'until the contest is completed',
      );
    }
    final latest = await repository.matrixRevisionRepository.latestForContest(
      contestId,
    );
    if (latest == null || !latest.isFinalized) {
      throw ContestStateError(
        'no_matrix',
        'draw the first matrix before adding or redrawing rounds',
      );
    }

    final current = [
      for (final round in await repository.roundRepository.listForContest(
        contestId,
      ))
        if (round.isCurrent) round,
    ]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    final lastRound = current.isEmpty ? 0 : current.last.ordinal;
    if (firstRound < 1 || firstRound > lastRound + 1) {
      throw ArgumentError.value(
        firstRound,
        'firstRound',
        'must be between 1 and ${lastRound + 1}, one past the last round',
      );
    }
    final replaced = [
      for (final round in current)
        if (round.ordinal >= firstRound) round,
    ];
    final kept = [
      for (final round in current)
        if (round.ordinal < firstRound) round,
    ];
    await _requireReplaceable(replaced);

    final configuration = await repository
        .contestConfigurationRevisionRepository
        .latestForContest(contestId);
    if (configuration == null) {
      throw ContestStateError(
        'not_configured',
        'save the contest configuration before drawing rounds',
      );
    }
    final options = configuration.config.coreOptions;
    // A seeded contest draws rounds up to its preliminary count like a
    // standard one; later rounds are seeded by the standings (see
    // _requireStandings).
    final preliminaryRounds = options.preliminaryRounds ?? 1;
    final seededMode = options.drawMode == DrawMode.seededManOnMan;
    final seeded = seededMode && firstRound > preliminaryRounds;
    if (seededMode && !seeded && firstRound + rounds - 1 > preliminaryRounds) {
      throw ContestStateError(
        'seeded_rounds_need_standings',
        'the preliminary rounds (1 to $preliminaryRounds) and the seeded '
            'rounds are drawn separately: seeded rounds need the standings '
            'after the preliminary scores',
      );
    }
    if (seeded && rounds != 1) {
      throw ContestStateError(
        'one_seeded_round',
        'a seeded round is drawn from the standings after the round before '
            'it, so seeded rounds are drawn one at a time',
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
    final history = await _history(kept, participations, teamOf);

    final requestedSeed = randomSeed ?? _newSeed();
    Map<String, Object?>? standings;
    final DrawResult drawn;
    if (seeded) {
      final places = await _requireStandings(
        contestId,
        asOfRound: firstRound - 1,
        kept: kept,
        participations: participations,
      );
      standings = {
        'as_of_round': firstRound - 1,
        'places': {
          for (final pilot in pilots)
            pilot.participationId.value: places[pilot.participationId],
        },
      };
      drawn = const DrawEngine().generateSeeded(
        pilots: pilots,
        places: places,
        groupsPerRound: groupsPerRound,
        laneMode: options.laneMode,
        seed: requestedSeed,
        history: history,
      );
    } else {
      drawn = await jobs.run(
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
          history: history,
        ),
      );
    }

    final extension = firstRound == lastRound + 1;
    final built = MatrixDrawBuilder(newId: _newId).build(
      contestId: contestId,
      id: id,
      revisionNumber: latest.revisionNumber + 1,
      previousRevisionId: latest.id,
      firstRound: firstRound,
      drawn: drawn.rounds,
      seed: drawn.seed,
      algorithmVersion: MatrixService.algorithmVersion,
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
      reason: _blankToNull(reason) ?? _defaultReason(extension, firstRound),
      actorId: actorId,
      now: _clock(),
      drawMode: seeded ? DrawMode.seededManOnMan : DrawMode.standardManOnMan,
      seedingStandings: standings,
    );

    final newByOrdinal = {
      for (final round in built.draw.rounds) round.ordinal: round,
    };
    await repository.matrixRevisionRepository.appendRedraw(
      FinalizedRedraw(
        draw: built.draw,
        placeholders: built.placeholders,
        numberedParticipations: MatrixDrawBuilder.numbered(participations),
        replacedRounds: [
          for (final round in replaced) _replace(round, newByOrdinal),
        ],
      ),
      metadata: metadata,
    );
    return MatrixService(repository).current(contestId);
  }

  static String _defaultReason(bool extension, int firstRound) =>
      extension ? 'rounds added' : 'redraw from round $firstRound';

  /// The places of the standings as of round [asOfRound], once every round
  /// up to it (the [kept] ones) is fully scored and validated.
  ///
  /// Throws a `ContestStateError` when a pilot's score in those rounds is not
  /// official yet, or the standings are missing, stale or preliminary.
  Future<Map<Id, int>> _requireStandings(
    Id contestId, {
    required int asOfRound,
    required List<Round> kept,
    required List<ContestParticipation> participations,
  }) async {
    final retired = {
      for (final p in participations)
        if (p.isRetired) p.id,
    };
    final placeholders = {
      for (final placeholder
          in await repository.scorePlaceholderRepository.listForContest(
            contestId,
          ))
        placeholder.assignmentId: placeholder,
    };
    var waiting = 0;
    for (final round in kept) {
      for (final assignment
          in await repository.matrixAssignmentRepository.listLiveForRound(
            round.id,
          )) {
        if (retired.contains(assignment.contestParticipationId)) continue;
        if (placeholders[assignment.id]?.state !=
            ScorePlaceholderState.official) {
          waiting++;
        }
      }
    }
    if (waiting > 0) {
      throw ContestStateError(
        'scores_incomplete',
        'a seeded round needs every score through round $asOfRound to be '
            'official; $waiting ${waiting == 1 ? 'is' : 'are'} not yet',
      );
    }
    final ContestResults results;
    try {
      results = await ResultsService(
        repository,
        clock: _clock,
      ).read(contestId, asOfRound: asOfRound);
    } on ArgumentError catch (e) {
      // ResultsService names the round argument when it has no such standing.
      if (e.name != 'asOfRound') rethrow;
      throw ContestStateError(
        'standings_missing',
        'recalculate the results before drawing a seeded round: there is no '
            'standing as of round $asOfRound',
      );
    }
    if (results.isStale || results.standings.any((s) => s.isPreliminary)) {
      throw ContestStateError(
        'standings_not_validated',
        'recalculate the results before drawing a seeded round: the '
            'standings as of round $asOfRound are stale or preliminary',
      );
    }
    return {
      for (final standing in results.standings)
        standing.contestParticipationId: standing.place,
    };
  }

  static String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// [round] as stored after the redraw: superseded by the new round with the
  /// same ordinal, or cancelled when the redraw ends before it.
  Round _replace(Round round, Map<int, Round> newByOrdinal) {
    final replacement = newByOrdinal[round.ordinal];
    return Round.fromJson({
      ...round.toJson(),
      if (replacement != null)
        'superseded_by_round_id': replacement.id.value
      else
        'status': 'Cancelled',
    });
  }

  /// Refuses a redraw over rounds that have a score, a locked group or a
  /// locked round.
  Future<void> _requireReplaceable(List<Round> replaced) async {
    for (final round in replaced) {
      if (round.status == RoundStatus.locked) {
        throw ContestStateError(
          'round_locked',
          'round ${round.ordinal} is locked; unlock it before redrawing',
        );
      }
      final groups = await repository.roundGroupRepository.listForRound(
        round.id,
      );
      if (groups.any((g) => g.isLocked)) {
        throw ContestStateError(
          'group_locked',
          'a group of round ${round.ordinal} is locked; unlock it before '
              'redrawing',
        );
      }
      for (final assignment
          in await repository.matrixAssignmentRepository.listLiveForRound(
            round.id,
          )) {
        final placeholder = await repository.scorePlaceholderRepository
            .findForAssignment(assignment.id);
        if (placeholder != null &&
            placeholder.state != ScorePlaceholderState.notEntered) {
          throw ContestStateError(
            'rounds_have_scores',
            'round ${round.ordinal} already has scores; only rounds without '
                'scores can be redrawn',
          );
        }
      }
    }
  }

  /// The groups of the [kept] rounds as the draw engine takes them.
  Future<List<List<List<DrawSlot>>>> _history(
    List<Round> kept,
    List<ContestParticipation> participations,
    Map<Id, Id> teamOf,
  ) async {
    final pilotOf = {
      for (final p in participations)
        p.id: DrawPilot(p.id, teamId: teamOf[p.id]),
    };
    final history = <List<List<DrawSlot>>>[];
    for (final round in kept) {
      final byGroup = <int, List<DrawSlot>>{};
      final live = await repository.matrixAssignmentRepository.listLiveForRound(
        round.id,
      );
      for (final MatrixAssignment assignment in live) {
        if (assignment.assignmentType == AssignmentType.reflight) continue;
        final pilot = pilotOf[assignment.contestParticipationId];
        if (pilot == null) continue;
        byGroup
            .putIfAbsent(assignment.group, () => [])
            .add(DrawSlot(pilot, assignment.lane));
      }
      final numbers = byGroup.keys.toList()..sort();
      history.add([for (final n in numbers) byGroup[n]!]);
    }
    return history;
  }

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }
}
