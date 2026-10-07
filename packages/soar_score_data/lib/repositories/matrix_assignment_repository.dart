import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Matrix assignments in the database.
class MatrixAssignmentRepository extends DriftRepository
    implements core.MatrixAssignmentRepository {
  MatrixAssignmentRepository(super.db, {super.stores});

  late final _store = store<core.MatrixAssignment>('MatrixAssignment');

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
}
