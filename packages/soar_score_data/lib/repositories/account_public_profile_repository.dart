import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Account public profiles in the database; backend only, so written without
/// a mutation.
class AccountPublicProfileRepository extends DriftRepository
    implements core.AccountPublicProfileRepository {
  AccountPublicProfileRepository(super.db, {super.stores});

  late final _store = store<core.AccountPublicProfile>('AccountPublicProfile');

  @override
  Future<core.AccountPublicProfile?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.AccountPublicProfile?> findForAccount(core.Id accountId) async {
    final found = await _store.whereId('account_id', accountId, orderBy: 'id');
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<core.AccountPublicProfile> save(
    core.AccountPublicProfile profile,
  ) async {
    await _store.upsertJson(_store.encode(profile));
    return profile;
  }
}
