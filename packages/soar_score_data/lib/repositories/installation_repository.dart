import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Installations in the database; backend only, so written without a
/// mutation.
class InstallationRepository extends DriftRepository
    implements core.InstallationRepository {
  InstallationRepository(super.db, {super.stores});

  late final _store = backendStore<core.Installation>('Installation');

  @override
  Future<core.Installation?> findById(core.Id id) async => _store.find(id);

  @override
  Future<List<core.Installation>> listForAccount(
    core.Id ownerAccountId,
  ) async => _store.whereId('owner_account_id', ownerAccountId, orderBy: 'id');

  @override
  Future<core.Installation> save(core.Installation installation) async {
    await _store.upsertJson(_store.encode(installation));
    return installation;
  }

  @override
  Future<bool> remove(core.Id id) async => _store.remove(id);
}
