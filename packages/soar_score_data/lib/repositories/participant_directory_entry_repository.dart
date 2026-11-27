import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Participant directory entries in the database; backend only, so written
/// without a mutation.
class ParticipantDirectoryEntryRepository extends DriftRepository
    implements core.ParticipantDirectoryEntryRepository {
  ParticipantDirectoryEntryRepository(super.db, {super.stores});

  late final _store = backendStore<core.ParticipantDirectoryEntry>(
    'ParticipantDirectoryEntry',
  );

  @override
  Future<core.ParticipantDirectoryEntry?> findById(core.Id id) async =>
      _store.find(id);

  @override
  Future<core.ParticipantDirectoryEntry?> findForAccount(
    core.Id accountId,
  ) async {
    final found = await _store.whereId('account_id', accountId, orderBy: 'id');
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<List<core.ParticipantDirectoryEntry>> listListedByFaiNumber(
    String faiNumber,
  ) => _listedWhere('fai_number', faiNumber);

  @override
  Future<List<core.ParticipantDirectoryEntry>> listListedByNationalOrgId(
    String nationalOrgId,
  ) => _listedWhere('national_org_id', nationalOrgId);

  Future<List<core.ParticipantDirectoryEntry>> _listedWhere(
    String column,
    String value,
  ) async {
    final found = await _store.whereText(column, value, orderBy: 'id');
    return [
      for (final entry in found)
        if (entry.isListed) entry,
    ];
  }

  @override
  Future<core.ParticipantDirectoryEntry> save(
    core.ParticipantDirectoryEntry entry,
  ) async {
    await _store.upsertJson(_store.encode(entry));
    return entry;
  }

  @override
  Future<bool> remove(core.Id id) async => _store.remove(id);
}
