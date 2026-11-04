import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'drift_repository.dart';
import 'unique_violation.dart';

/// Matrix revisions, and the draws stored in them, in the database.
class MatrixRevisionRepository extends DriftRepository
    implements core.MatrixRevisionRepository {
  MatrixRevisionRepository(super.db, {super.stores});

  late final _store = store<core.MatrixRevision>('MatrixRevision');
  late final _audits = AuditEventRepository(db, stores: stores);

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
    core.AuditEvent? audit,
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
    if (audit != null) await _audits.append(audit);
    return finalized;
  });

  @override
  Future<core.FinalizedRedraw> appendRedraw(
    core.FinalizedRedraw finalized, {
    required int expectedBaseRevision,
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) async {
    final contestId = finalized.draw.revision.contestId;
    try {
      return await unitOfWork.run((context) async {
        // Re-checked in the transaction: a matrix that moved on since the
        // caller read it stores nothing.
        final latest = await latestForContest(contestId);
        if (latest == null || latest.revisionNumber != expectedBaseRevision) {
          throw _staleMatrix();
        }
        // The replaced rounds go first: a superseded round leaves the unique
        // index on live ordinals before its replacement enters it.
        for (final round in finalized.replacedRounds) {
          await context.save(round, metadata: metadata.forPart(round.id.value));
        }
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
        if (audit != null) await _audits.append(audit);
        return finalized;
      });
    } on Object catch (error) {
      // A redraw that passed the check above can still lose it to a concurrent
      // redraw: both read the same newest revision, both claim the successor
      // index, and one is rolled back. When the matrix moved on, answer the
      // same stale_matrix the check would have; otherwise rethrow the
      // original error, so a rule the winner's commit broke still surfaces.
      if (!isUniqueViolation(error)) rethrow;
      final latest = await latestForContest(contestId);
      if (latest == null || latest.revisionNumber != expectedBaseRevision) {
        throw _staleMatrix();
      }
      rethrow;
    }
  }

  static core.ContestStateError _staleMatrix() => core.ContestStateError(
    'stale_matrix',
    'the matrix moved on since it was read',
  );
}
