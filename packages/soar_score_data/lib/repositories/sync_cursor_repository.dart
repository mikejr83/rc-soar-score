import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Sync cursors in the database; backend only, so written without a
/// mutation.
class SyncCursorRepository extends DriftRepository
    implements core.SyncCursorRepository {
  SyncCursorRepository(super.db, {super.stores});

  late final _store = backendStore<core.SyncCursor>('SyncCursor');

  @override
  Future<core.SyncCursor?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.SyncCursor?> findForContest({
    required core.Id installationId,
    required core.Id contestId,
  }) async {
    final found = await listForInstallation(installationId);
    return found.where((c) => c.contestId == contestId).firstOrNull;
  }

  @override
  Future<core.SyncCursor?> findForOwner({
    required core.Id installationId,
    required core.Id ownerAccountId,
  }) async {
    final found = await listForInstallation(installationId);
    return found.where((c) => c.ownerAccountId == ownerAccountId).firstOrNull;
  }

  @override
  Future<List<core.SyncCursor>> listForInstallation(
    core.Id installationId,
  ) async => _store.whereId('installation_id', installationId, orderBy: 'id');

  @override
  Future<core.SyncCursor> save(core.SyncCursor cursor) async {
    await _store.upsertJson(_store.encode(cursor));
    return cursor;
  }

  @override
  Future<bool> remove(core.Id id) async => _store.remove(id);
}
