import 'package:soar_score_core/soar_score_core.dart';

/// In-memory [AccountRepository] for auth tests.
class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> byId = {};

  @override
  Future<Account?> findById(Id id) async => byId[id.value];

  @override
  Future<Account?> findByEmail(String email) async => byId.values
      .where((a) => a.email == email.toLowerCase())
      .cast<Account?>()
      .firstOrNull;

  @override
  Future<Account?> findDeletedUser() async => null;

  @override
  Future<Account> save(Account account) async {
    final email = account.email;
    if (email != null &&
        byId.values.any((a) => a.id != account.id && a.email == email)) {
      throw StateError('duplicate email');
    }
    return byId[account.id.value] = account;
  }
}

/// In-memory [AccountIdentityRepository] for auth tests.
class FakeAccountIdentityRepository implements AccountIdentityRepository {
  final Map<String, AccountIdentity> byId = {};

  /// Called inside [save] before the identity is stored, to simulate a
  /// concurrent first request.
  void Function()? beforeSave;

  @override
  Future<AccountIdentity?> findById(Id id) async => byId[id.value];

  @override
  Future<AccountIdentity?> findBySubject({
    required String issuer,
    required String subject,
  }) async => byId.values
      .where((i) => i.issuer == issuer && i.subject == subject)
      .cast<AccountIdentity?>()
      .firstOrNull;

  @override
  Future<List<AccountIdentity>> listForAccount(Id accountId) async =>
      byId.values.where((i) => i.accountId == accountId).toList();

  @override
  Future<AccountIdentity> save(AccountIdentity identity) async {
    beforeSave?.call();
    final clash = byId.values.any(
      (i) =>
          i.id != identity.id &&
          i.issuer == identity.issuer &&
          i.subject == identity.subject,
    );
    if (clash) throw StateError('duplicate identity');
    return byId[identity.id.value] = identity;
  }

  @override
  Future<bool> remove(Id id) async => byId.remove(id.value) != null;
}
