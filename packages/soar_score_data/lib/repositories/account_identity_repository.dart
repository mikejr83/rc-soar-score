import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Account identities in the database; backend only, so written without a
/// mutation.
class AccountIdentityRepository extends DriftRepository
    implements core.AccountIdentityRepository {
  AccountIdentityRepository(super.db, {super.stores});

  late final _store = backendStore<core.AccountIdentity>('AccountIdentity');

  @override
  Future<core.AccountIdentity?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.AccountIdentity?> findBySubject({
    required String issuer,
    required String subject,
  }) async {
    final found = await _store.whereText('subject', subject, orderBy: 'id');
    return found.where((i) => i.issuer == issuer).firstOrNull;
  }

  @override
  Future<List<core.AccountIdentity>> listForAccount(core.Id accountId) async =>
      _store.whereId('account_id', accountId, orderBy: 'id');

  @override
  Future<core.AccountIdentity> save(core.AccountIdentity identity) async {
    await _store.upsertJson(_store.encode(identity));
    return identity;
  }

  @override
  Future<bool> remove(core.Id id) async => _store.remove(id);
}
