import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Matrix assignments in the database.
class MatrixAssignmentRepository extends DriftRepository
    implements core.MatrixAssignmentRepository {
  MatrixAssignmentRepository(super.db, {super.stores});

  late final _store = store<core.MatrixAssignment>('MatrixAssignment');
  late final _placeholders = store<core.ScorePlaceholder>('ScorePlaceholder');
  late final _flightResults = store<core.FlightResult>('FlightResult');
  late final _standings = store<core.ParticipationStanding>(
    'ParticipationStanding',
  );

  @override
  Future<core.MatrixAssignment?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.MatrixAssignment>> listForRevision(
    core.Id matrixRevisionId,
  ) => _store.whereId(
    'matrix_revision_id',
    matrixRevisionId,
    orderBy: 'created_at, id',
  );

  @override
  Future<List<core.MatrixAssignment>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'created_at, id',
  );

  @override
  Future<List<core.MatrixAssignment>> listLiveForRound(core.Id roundId) async {
    final scheduled = await _store.whereId(
      'scheduled_round_id',
      roundId,
      orderBy: 'created_at, id',
    );
    return [
      for (final assignment in scheduled)
        if (assignment.supersededByAssignmentId == null) assignment,
    ];
  }

  @override
  Future<core.MatrixAssignment> append(
    core.MatrixAssignment assignment, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.append(assignment, metadata: metadata),
  );

  @override
  Future<core.MatrixAssignment> move(
    core.MatrixAssignment moved, {
    required core.ScorePlaceholder placeholder,
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final stored = await context.moveAssignment(moved, metadata: metadata);
    await context.save(
      placeholder,
      metadata: metadata.forPart(placeholder.id.value),
    );
    return stored;
  });

  @override
  Future<core.MatrixAssignment> addLate(
    core.MatrixAssignment lateAdd, {
    required core.ScorePlaceholder placeholder,
    core.ContestParticipation? numberedParticipation,
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final stored = await context.append(lateAdd, metadata: metadata);
    await context.save(
      placeholder,
      metadata: metadata.forPart(placeholder.id.value),
    );
    if (numberedParticipation != null) {
      await context.save(
        numberedParticipation,
        metadata: metadata.forPart(numberedParticipation.id.value),
      );
    }
    return stored;
  });

  @override
  Future<int> removeForParticipation(
    core.Id contestParticipationId, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final assignments = await _store.whereId(
      'contest_participation_id',
      contestParticipationId,
      orderBy: 'created_at, id',
    );
    final placeholders = await _placeholders.whereId(
      'contest_participation_id',
      contestParticipationId,
    );
    for (final placeholder in placeholders) {
      if (placeholder.state != core.ScorePlaceholderState.notEntered ||
          placeholder.scoreRevision > 0) {
        throw StateError(
          'the slot ${placeholder.assignmentId.value} holds a score',
        );
      }
    }
    // Derived rows are recomputed, never mutated, so they leave without a
    // tombstone.
    await _flightResults.removeWhereId(
      'contest_participation_id',
      contestParticipationId,
    );
    await _standings.removeWhereId(
      'contest_participation_id',
      contestParticipationId,
    );
    final placeholderOf = {
      for (final placeholder in placeholders)
        placeholder.assignmentId: placeholder,
    };
    // A move points at its source, so the moved row goes before it.
    for (final assignment in _movesFirst(assignments)) {
      final placeholder = placeholderOf[assignment.id];
      if (placeholder != null) {
        await context.delete(
          placeholder,
          metadata: metadata.forPart(placeholder.id.value),
        );
      }
      await context.removeAssignment(
        assignment,
        metadata: metadata.forPart(assignment.id.value),
      );
    }
    return assignments.length;
  });

  /// [assignments] with every row ahead of the row it moves from.
  List<core.MatrixAssignment> _movesFirst(
    List<core.MatrixAssignment> assignments,
  ) {
    final byId = {for (final a in assignments) a.id: a};
    int depth(core.MatrixAssignment a) {
      var n = 0;
      for (
        var source = byId[a.sourceAssignmentId];
        source != null;
        source = byId[source.sourceAssignmentId]
      ) {
        n++;
      }
      return n;
    }

    return [...assignments]..sort((a, b) => depth(b).compareTo(depth(a)));
  }
}
