import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../sync/sql_placeholders.dart';
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

  @override
  Future<bool> claimProfileRefresh(
    core.Id id, {
    required DateTime? expected,
    required DateTime at,
  }) async {
    _store; // fails on a database without backend tables
    final changed = await db.customUpdate(
      portableSql(
        db,
        'UPDATE accounts SET profile_refreshed_at = ? WHERE id = ? AND '
        '${expected == null ? 'profile_refreshed_at IS NULL' : 'profile_refreshed_at = ?'}',
      ),
      variables: [
        Variable<String>(core.formatUtcTimestamp(at)),
        Variable<String>(id.value),
        if (expected != null)
          Variable<String>(core.formatUtcTimestamp(expected)),
      ],
      updates: {db.accounts},
    );
    return changed > 0;
  }

  @override
  Future<bool> applyProfile(
    core.Id id, {
    required String firstName,
    required String lastName,
    required String? email,
    required bool emailVerified,
    required DateTime now,
  }) async {
    _store;
    final changed = await db.customUpdate(
      portableSql(
        db,
        'UPDATE accounts SET first_name = ?, last_name = ?, email = ?, '
        'email_verified = ?, updated_at = ? WHERE id = ?',
      ),
      variables: [
        Variable<String>(firstName),
        Variable<String>(lastName),
        Variable<String>(email?.trim().toLowerCase()),
        Variable<bool>(emailVerified),
        Variable<String>(core.formatUtcTimestamp(now)),
        Variable<String>(id.value),
      ],
      updates: {db.accounts},
    );
    return changed > 0;
  }
}
