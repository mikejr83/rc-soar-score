import 'package:soar_score_core/soar_score_core.dart' as core;

/// In-memory accounts for tests, keyed by id.
class StubAccountRepository implements core.AccountRepository {
  final Map<String, core.Account> byId = {};

  @override
  Future<core.Account?> findById(core.Id id) async => byId[id.value];

  @override
  Future<core.Account?> findByEmail(String email) async => null;

  @override
  Future<core.Account?> findDeletedUser() async => null;

  @override
  Future<core.Account> save(core.Account account) async =>
      byId[account.id.value] = account;
}

/// In-memory account aliases for tests; like the real repository, the first
/// claim of an id stands.
class StubAccountAliasRepository implements core.AccountAliasRepository {
  final Map<String, core.AccountAlias> byId = {};

  @override
  Future<core.AccountAlias?> findById(core.Id id) async => byId[id.value];

  @override
  Future<List<core.AccountAlias>> listForAccount(core.Id accountId) async => [
    for (final alias in byId.values)
      if (alias.accountId == accountId) alias,
  ];

  @override
  Future<core.AccountAlias> claim({
    required core.Id localAccountId,
    required core.Id accountId,
    required DateTime claimedAt,
  }) async => byId.putIfAbsent(
    localAccountId.value,
    () => core.AccountAlias(
      id: localAccountId,
      accountId: accountId,
      claimedAt: claimedAt,
    ),
  );

  @override
  Future<core.Id> resolve(core.Id id) async => byId[id.value]?.accountId ?? id;
}
