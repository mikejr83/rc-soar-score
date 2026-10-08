import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Accounts in the database; backend only, so written without a mutation.
class AccountRepository extends DriftRepository
    implements core.AccountRepository {
  AccountRepository(super.db, {super.stores});

  late final _store = backendStore<core.Account>('Account');

  @override
  Future<core.Account?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.Account?> findByEmail(String email) async {
    final found = await _store.whereText(
      'email',
      email.trim().toLowerCase(),
      orderBy: 'id',
    );
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<core.Account?> findDeletedUser() async {
    final found = await _store.whereText('kind', 'deleted', orderBy: 'id');
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<core.Account> save(core.Account account) async {
    await _store.upsertJson(_store.encode(account));
    return account;
  }
}
