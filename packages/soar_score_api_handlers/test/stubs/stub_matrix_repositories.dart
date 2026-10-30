import 'package:soar_score_core/soar_score_core.dart';

import 'stub_contest_repository.dart';
import 'stub_participant_repositories.dart';

/// Matrix revisions in memory, with the draws stored in them.
///
/// A test can also mark contests in [drawnContests]: they report a matrix
/// revision without any rounds, which is enough for rules that only ask
/// whether a draw exists. [appendFinalizedDraw] stores through the other
/// stubs, as the real repository stores in one transaction.
class StubMatrixRevisionRepository implements MatrixRevisionRepository {
  StubMatrixRevisionRepository(
    this._contests,
    this._participations,
    this._rounds,
    this._groups,
    this._assignments,
    this._placeholders,
  );

  final StubContestRepository _contests;
  final StubContestParticipationRepository _participations;
  final StubRoundRepository _rounds;
  final StubRoundGroupRepository _groups;
  final StubMatrixAssignmentRepository _assignments;
  final StubScorePlaceholderRepository _placeholders;

  final Set<Id> drawnContests = {};
  final List<MatrixRevision> revisions = [];

  /// The audit events stored with a draw, oldest first.
  final List<AuditEvent> audits = [];

  @override
  Future<MatrixRevision?> findById(Id id) async =>
      revisions.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<MatrixRevision>> listForContest(Id contestId) async =>
      revisions.where((r) => r.contestId == contestId).toList()
        ..sort((a, b) => a.revisionNumber.compareTo(b.revisionNumber));

  @override
  Future<MatrixRevision?> latestForContest(Id contestId) async {
    final stored = (await listForContest(contestId)).lastOrNull;
    if (stored != null || !drawnContests.contains(contestId)) {
      return stored;
    }
    return MatrixRevision(
      id: Id.create(),
      contestId: contestId,
      revisionNumber: 1,
      firstRound: 1,
      lastRound: 1,
      drawMode: DrawMode.values.first,
      randomSeed: 1,
      algorithmVersion: 'test',
      drawConfig: const {},
      seedingSnapshot: const {},
      createdBy: Id.create(),
      createdAt: DateTime.utc(2026, 10, 1),
    );
  }

  @override
  Future<FinalizedDraw> appendFinalizedDraw(
    FinalizedDraw finalized, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  }) async {
    // The contest goes first: a stale one stores nothing.
    final contest = await _contests.save(
      finalized.contest,
      metadata: metadata.forPart(finalized.contest.id.value),
    );
    final draw = finalized.draw;
    revisions.add(draw.revision);
    _rounds.rounds.addAll(draw.rounds);
    _groups.groups.addAll(draw.groups);
    _assignments.stored.addAll(draw.assignments);
    _placeholders.stored.addAll(finalized.placeholders);
    for (final participation in finalized.numberedParticipations) {
      await _participations.save(
        participation,
        metadata: metadata.forPart(participation.id.value),
      );
    }
    if (audit != null) audits.add(audit);
    return FinalizedDraw(
      draw: draw,
      placeholders: finalized.placeholders,
      numberedParticipations: finalized.numberedParticipations,
      contest: contest,
    );
  }

  @override
  Future<FinalizedRedraw> appendRedraw(
    FinalizedRedraw finalized, {
    required int expectedBaseRevision,
    required MutationMetadata metadata,
    AuditEvent? audit,
  }) async {
    // Re-checked as the real repository re-checks it in its transaction.
    final latest = await latestForContest(finalized.draw.revision.contestId);
    if (latest == null || latest.revisionNumber != expectedBaseRevision) {
      throw ContestStateError(
        'stale_matrix',
        'the matrix moved on since it was read',
      );
    }
    for (final round in finalized.replacedRounds) {
      final index = _rounds.rounds.indexWhere((r) => r.id == round.id);
      _rounds.rounds[index] = round;
    }
    final draw = finalized.draw;
    revisions.add(draw.revision);
    _rounds.rounds.addAll(draw.rounds);
    _groups.groups.addAll(draw.groups);
    _assignments.stored.addAll(draw.assignments);
    _placeholders.stored.addAll(finalized.placeholders);
    for (final participation in finalized.numberedParticipations) {
      await _participations.save(participation, metadata: metadata);
    }
    if (audit != null) audits.add(audit);
    return finalized;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Rounds in memory.
class StubRoundRepository implements RoundRepository {
  final List<Round> rounds = [];

  @override
  Future<Round?> findById(Id id) async =>
      rounds.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<Round>> listForContest(Id contestId) async =>
      rounds.where((r) => r.contestId == contestId).toList()
        ..sort((a, b) => a.ordinal.compareTo(b.ordinal));

  @override
  Future<List<Round>> listForRevision(Id matrixRevisionId) async =>
      rounds.where((r) => r.matrixRevisionId == matrixRevisionId).toList()
        ..sort((a, b) => a.ordinal.compareTo(b.ordinal));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Round groups in memory.
class StubRoundGroupRepository implements RoundGroupRepository {
  final List<RoundGroup> groups = [];

  @override
  Future<List<RoundGroup>> listForContest(Id contestId) async =>
      groups.where((g) => g.contestId == contestId).toList();

  @override
  Future<List<RoundGroup>> listForRound(Id roundId) async =>
      groups.where((g) => g.roundId == roundId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Score placeholders in memory, for tests to inspect.
class StubScorePlaceholderRepository implements ScorePlaceholderRepository {
  final List<ScorePlaceholder> stored = [];

  /// When set, listing the placeholders fails, like a database that has gone
  /// away.
  bool failListing = false;

  @override
  Future<List<ScorePlaceholder>> listForContest(Id contestId) async {
    if (failListing) {
      throw StateError('the database is unreachable');
    }
    return [
      for (final placeholder in stored)
        if (placeholder.contestId == contestId) placeholder,
    ];
  }

  @override
  Future<List<ScorePlaceholder>> listForParticipation(
    Id contestParticipationId,
  ) async => [
    for (final placeholder in stored)
      if (placeholder.contestParticipationId == contestParticipationId)
        placeholder,
  ];

  @override
  Future<ScorePlaceholder?> findForAssignment(Id assignmentId) async => stored
      .where((placeholder) => placeholder.assignmentId == assignmentId)
      .firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Matrix assignments in memory. A test can also mark participations in
/// [participationsWithAssignments]: they report one assignment each, which is
/// enough for rules that only ask whether a pilot has flown.
class StubMatrixAssignmentRepository implements MatrixAssignmentRepository {
  final List<MatrixAssignment> stored = [];
  final Set<Id> participationsWithAssignments = {};

  /// The placeholders a move stores; set by the repository that owns them.
  StubScorePlaceholderRepository? placeholders;

  @override
  Future<List<MatrixAssignment>> listForRevision(Id matrixRevisionId) async => [
    for (final assignment in stored)
      if (assignment.matrixRevisionId == matrixRevisionId) assignment,
  ];

  /// The participations a late add may number; set by the repository.
  StubContestParticipationRepository? participations;

  @override
  Future<MatrixAssignment> addLate(
    MatrixAssignment lateAdd, {
    required ScorePlaceholder placeholder,
    ContestParticipation? numberedParticipation,
    required MutationMetadata metadata,
  }) async {
    stored.add(lateAdd);
    placeholders?.stored.add(placeholder);
    if (numberedParticipation != null) {
      await participations?.save(numberedParticipation, metadata: metadata);
    }
    return lateAdd;
  }

  /// Participations whose matrix rows were removed with them.
  final Set<Id> removedFor = {};

  /// Removes the rows of [contestParticipationId], as the real repository
  /// does inside a participation save or delete; returns how many went.
  Future<int> removeRowsOf(Id contestParticipationId) async {
    final rows = await listForParticipation(contestParticipationId);
    stored.removeWhere(
      (assignment) =>
          assignment.contestParticipationId == contestParticipationId,
    );
    placeholders?.stored.removeWhere(
      (placeholder) =>
          placeholder.contestParticipationId == contestParticipationId,
    );
    participationsWithAssignments.remove(contestParticipationId);
    removedFor.add(contestParticipationId);
    return rows.length;
  }

  @override
  Future<MatrixAssignment?> findById(Id id) async =>
      stored.where((assignment) => assignment.id == id).firstOrNull;

  @override
  Future<MatrixAssignment> move(
    MatrixAssignment moved, {
    required ScorePlaceholder placeholder,
    required MutationMetadata metadata,
  }) async {
    final index = stored.indexWhere((a) => a.id == moved.sourceAssignmentId);
    stored[index] = MatrixAssignment.fromJson({
      ...stored[index].toJson(),
      'superseded_by_assignment_id': moved.id.value,
    });
    stored.add(moved);
    placeholders?.stored.add(placeholder);
    return moved;
  }

  @override
  Future<List<MatrixAssignment>> listLiveForRound(Id roundId) async => [
    for (final assignment in stored)
      if (assignment.scheduledRoundId == roundId && !assignment.isSuperseded)
        assignment,
  ];

  @override
  Future<List<MatrixAssignment>> listForParticipation(
    Id contestParticipationId,
  ) async {
    final matching = [
      for (final assignment in stored)
        if (assignment.contestParticipationId == contestParticipationId)
          assignment,
    ];
    if (matching.isNotEmpty ||
        !participationsWithAssignments.contains(contestParticipationId)) {
      return matching;
    }
    final round = Id.create();
    return [
      MatrixAssignment(
        id: Id.create(),
        contestId: Id.create(),
        matrixRevisionId: Id.create(),
        contestParticipationId: contestParticipationId,
        scheduledRoundId: round,
        creditedRoundId: round,
        group: 1,
        assignmentType: AssignmentType.original,
        actorId: Id.create(),
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Re-flight participants: none, in every handler test that asks.
class StubReFlightParticipantRepository
    implements ReFlightParticipantRepository {
  @override
  Future<List<ReFlightParticipant>> listForParticipation(
    Id contestParticipationId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
