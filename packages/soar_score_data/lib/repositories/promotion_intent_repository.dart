import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../sync/table_mapper.dart';
import 'drift_repository.dart';

/// The `promote_score` intents of an installation's outbox.
///
/// An intent is a `ScorePromotion` mutation that is still `Pending`; deciding
/// it (a receipt or a refusal) takes it out of the pending list.
class PromotionIntentRepository extends DriftRepository
    implements core.PromotionIntentRepository {
  PromotionIntentRepository(super.db, {super.stores});

  late final _mutations = TableMapper(
    db,
    db.mutationRecords,
    jsonColumns: {'payload'},
  );

  @override
  Future<List<core.PendingPromotion>> pendingForContest(
    core.Id contestId,
  ) async {
    final rows = await _mutations.where(
      "entity_type = ? AND outcome = 'Pending' AND contest_id = ?",
      [
        Variable<String>(core.promotionReceiptEntityType),
        Variable<String>(contestId.value),
      ],
      orderBy: 'client_time, id',
    );
    return [
      for (final row in rows)
        _intentOf(core.MutationRecord.fromJson(row), contestId),
    ];
  }

  @override
  Future<core.PendingPromotion?> pendingForAssignment(
    core.Id contestId,
    core.Id assignmentId,
  ) async =>
      (await pendingForContest(contestId))
          .where((i) => i.assignmentId == assignmentId)
          .firstOrNull;

  /// Whether [contestId] is still in its first upload: this installation
  /// created the contest and the creation is not accepted yet. A contest that
  /// came from the service has no creation of its own, so it never is.
  Future<bool> firstUploadOpen(core.Id contestId) async {
    final rows = await _mutations.where(
      "entity_type = 'Contest' AND entity_id = ? AND contest_id = ? "
      "AND base_revision IS NULL AND outcome <> 'Accepted'",
      [Variable<String>(contestId.value), Variable<String>(contestId.value)],
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> queue(
    core.PendingPromotion intent, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.recordOperation(
      entityType: core.promotionReceiptEntityType,
      entityId: intent.operationId,
      contestId: intent.contestId,
      payload: core.VersionedPayload(
        version: 1,
        data: {
          'operation': core.SyncCapabilities.promoteScore,
          'operation_version': 1,
          'assignment_id': intent.assignmentId.value,
          'source_attempt_id': intent.sourceAttemptId.value,
          'expected_score_revision': intent.expectedScoreRevision,
        },
      ).toJson(),
      metadata: metadata,
    ),
  );

  core.PendingPromotion _intentOf(core.MutationRecord record, core.Id contest) {
    final data = (record.payload['data']! as Map).cast<String, Object?>();
    return core.PendingPromotion(
      operationId: record.entityId,
      contestId: contest,
      assignmentId: core.Id.parse(data['assignment_id']! as String),
      sourceAttemptId: core.Id.parse(data['source_attempt_id']! as String),
      expectedScoreRevision: data['expected_score_revision']! as int,
      queuedAt: record.clientTime,
    );
  }
}
