import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Matrix revisions, and the draws stored in them, in the database.
class MatrixRevisionRepository extends DriftRepository
    implements core.MatrixRevisionRepository {
  MatrixRevisionRepository(super.db, {super.stores});

  late final _store = store<core.MatrixRevision>('MatrixRevision');

  @override
  Future<core.MatrixRevision?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.MatrixRevision>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'revision_number');

  @override
  Future<core.MatrixRevision?> latestForContest(core.Id contestId) async {
    final revisions = await listForContest(contestId);
    return revisions.isEmpty ? null : revisions.last;
  }

  @override
  Future<core.MatrixDraw> appendDraw(
    core.MatrixDraw draw, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    await context.append(draw.revision, metadata: metadata);
    for (final round in draw.rounds) {
      await context.save(round, metadata: metadata.forPart(round.id.value));
    }
    for (final group in draw.groups) {
      await context.save(group, metadata: metadata.forPart(group.id.value));
    }
    for (final assignment in draw.assignments) {
      await context.append(
        assignment,
        metadata: metadata.forPart(assignment.id.value),
      );
    }
    return draw;
  });

  @override
  Future<core.FinalizedDraw> appendFinalizedDraw(
    core.FinalizedDraw finalized, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final draw = finalized.draw;
    await context.append(draw.revision, metadata: metadata);
    for (final round in draw.rounds) {
      await context.save(round, metadata: metadata.forPart(round.id.value));
    }
    for (final group in draw.groups) {
      await context.save(group, metadata: metadata.forPart(group.id.value));
    }
    for (final assignment in draw.assignments) {
      await context.append(
        assignment,
        metadata: metadata.forPart(assignment.id.value),
      );
    }
    for (final placeholder in finalized.placeholders) {
      await context.save(
        placeholder,
        metadata: metadata.forPart(placeholder.id.value),
      );
    }
    for (final participation in finalized.numberedParticipations) {
      await context.save(
        participation,
        metadata: metadata.forPart(participation.id.value),
      );
    }
    await context.save(
      finalized.contest,
      metadata: metadata.forPart(finalized.contest.id.value),
    );
    return finalized;
  });
}
