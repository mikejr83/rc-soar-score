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

  /// Called inside [claimProfileRefresh] before the compare, to simulate a
  /// concurrent request.
  void Function()? beforeClaim;

  @override
  Future<bool> claimProfileRefresh(
    Id id, {
    required DateTime? expected,
    required DateTime at,
  }) async {
    beforeClaim?.call();
    final account = byId[id.value];
    if (account == null || account.profileRefreshedAt != expected) return false;
    byId[id.value] = _with(account, profileRefreshedAt: at);
    return true;
  }

  @override
  Future<bool> applyProfile(
    Id id, {
    required String firstName,
    required String lastName,
    required String? email,
    required bool emailVerified,
    required DateTime now,
  }) async {
    final account = byId[id.value];
    if (account == null) return false;
    if (email != null &&
        byId.values.any((a) => a.id != id && a.email == email)) {
      throw StateError('duplicate email');
    }
    byId[id.value] = _with(
      account,
      firstName: firstName,
      lastName: lastName,
      email: email,
      emailVerified: emailVerified,
      updatedAt: now,
    );
    return true;
  }

  Account _with(
    Account a, {
    String? firstName,
    String? lastName,
    Object? email = _keep,
    bool? emailVerified,
    DateTime? profileRefreshedAt,
    DateTime? updatedAt,
  }) => Account(
    id: a.id,
    firstName: firstName ?? a.firstName,
    lastName: lastName ?? a.lastName,
    email: identical(email, _keep) ? a.email : email as String?,
    emailVerified: emailVerified ?? a.emailVerified,
    kind: a.kind,
    status: a.status,
    archivedAt: a.archivedAt,
    isSystemAdmin: a.isSystemAdmin,
    preferredTimeZone: a.preferredTimeZone,
    preferredLocale: a.preferredLocale,
    profileRefreshedAt: profileRefreshedAt ?? a.profileRefreshedAt,
    createdAt: a.createdAt,
    updatedAt: updatedAt ?? a.updatedAt,
  );
}

const Object _keep = Object();

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
