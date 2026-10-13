import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../sync/sql_placeholders.dart';
import 'drift_repository.dart';

/// Claimed Local account ids in the database; backend only, so written
/// without a mutation.
class AccountAliasRepository extends DriftRepository
    implements core.AccountAliasRepository {
  AccountAliasRepository(super.db, {super.stores});

  late final _store = backendStore<core.AccountAlias>('AccountAlias');

  @override
  Future<core.AccountAlias?> findById(core.Id id) async => _store.find(id);

  @override
  Future<List<core.AccountAlias>> listForAccount(core.Id accountId) async =>
      _store.whereId('account_id', accountId, orderBy: 'id');

  @override
  Future<core.AccountAlias> claim({
    required core.Id localAccountId,
    required core.Id accountId,
    required DateTime claimedAt,
  }) async {
    final alias = core.AccountAlias(
      id: localAccountId,
      accountId: accountId,
      claimedAt: claimedAt,
    );
    final json = _store.encode(alias);
    // Insert only: two concurrent claims of one id must not overwrite each
    // other, so the first stands and the second reads it back.
    await db.customInsert(
      portableSql(
        db,
        'INSERT INTO account_aliases (id, account_id, claimed_at) '
        'VALUES (?, ?, ?) ON CONFLICT (id) DO NOTHING',
      ),
      variables: [
        Variable<String>(json['id']! as String),
        Variable<String>(json['account_id']! as String),
        Variable<String>(json['claimed_at']! as String),
      ],
      updates: {db.accountAliases},
    );
    return (await _store.find(localAccountId))!;
  }

  @override
  Future<core.Id> resolve(core.Id id) async =>
      (await _store.find(id))?.accountId ?? id;
}
