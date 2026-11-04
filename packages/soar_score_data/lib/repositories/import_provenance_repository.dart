import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Import stamps in the database.
class ImportProvenanceRepository extends DriftRepository
    implements core.ImportProvenanceRepository {
  ImportProvenanceRepository(super.db, {super.stores});

  late final _store = store<core.ImportProvenance>('ImportProvenance');

  @override
  Future<core.ImportProvenance?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ImportProvenance>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'imported_at, id');

  @override
  Future<core.ImportProvenance?> findForEntity(core.Id stampedEntityId) async {
    final rows = await _store.whereId(
      'stamped_entity_id',
      stampedEntityId,
      orderBy: 'imported_at, id',
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<core.ImportProvenance?> findByDedupeKey(
    core.Id ownerAccountId,
    String dedupeKey,
  ) async {
    final rows = await _store.whereIdAndText(
      'owner_account_id',
      ownerAccountId,
      textColumn: 'dedupe_key',
      text: dedupeKey,
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<core.ImportProvenance> save(
    core.ImportProvenance stamp, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(stamp, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final stamp = await _store.find(id);
        if (stamp == null) return false;
        await context.delete(stamp, metadata: metadata);
        return true;
      });
}
