import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fake_account_repositories.dart';

class _Profiles implements UserProfileSource {
  _Profiles(this.profile);

  UserProfile? profile;
  int fetches = 0;

  @override
  Future<UserProfile> fetch(String accessToken) async {
    fetches++;
    return profile ?? (throw const UserProfileUnavailableException('down'));
  }
}

void main() {
  const token = VerifiedToken(
    issuer: 'https://tenant.us.auth0.com/',
    subject: 'auth0|abc',
  );
  late FakeAccountRepository accounts;
  late FakeAccountIdentityRepository identities;
  late _Profiles profiles;
  late AccountPrincipalResolver resolver;

  setUp(() {
    accounts = FakeAccountRepository();
    identities = FakeAccountIdentityRepository();
    profiles = _Profiles(
      const UserProfile(
        givenName: 'Ada',
        familyName: 'Lovelace',
        email: 'Ada@Example.com',
        emailVerified: true,
      ),
    );
    resolver = AccountPrincipalResolver(
      accounts: accounts,
      identities: identities,
      profiles: profiles,
    );
  });

  test('registers an account for a new identity', () async {
    final principal = await resolver.resolve(token, 'jwt');

    final account = accounts.byId.values.single;
    expect(principal.accountId, account.id);
    expect(principal.authority, Authority.director);
    expect(account.kind, AccountKind.registered);
    expect(account.firstName, 'Ada');
    expect(account.lastName, 'Lovelace');
    expect(account.email, 'ada@example.com');
    expect(account.emailVerified, isTrue);
    expect(account.isSystemAdmin, isFalse);
    final identity = identities.byId.values.single;
    expect(identity.accountId, account.id);
    expect(identity.issuer, token.issuer);
    expect(identity.subject, token.subject);
  });

  test(
    'a returning identity reuses its account without a profile call',
    () async {
      final first = await resolver.resolve(token, 'jwt');
      final second = await resolver.resolve(token, 'jwt');

      expect(second.accountId, first.accountId);
      expect(accounts.byId, hasLength(1));
      expect(profiles.fetches, 1);
    },
  );

  test('the same subject at another issuer is another account', () async {
    final first = await resolver.resolve(token, 'jwt');
    final second = await resolver.resolve(
      const VerifiedToken(issuer: 'https://other/', subject: 'auth0|abc'),
      'jwt',
    );

    expect(second.accountId, isNot(first.accountId));
  });

  test('does not copy an email another account already uses', () async {
    await resolver.resolve(token, 'jwt');

    final second = await resolver.resolve(
      const VerifiedToken(
        issuer: 'https://tenant.us.auth0.com/',
        subject: 'google|1',
      ),
      'jwt',
    );

    final account = accounts.byId[second.accountId.value]!;
    expect(account.email, isNull);
    expect(account.emailVerified, isFalse);
  });

  test('does not mark an unverified email as verified', () async {
    profiles.profile = const UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: 'ada@example.com',
    );

    await resolver.resolve(token, 'jwt');

    expect(accounts.byId.values.single.emailVerified, isFalse);
  });

  group('names', () {
    Future<Account> register(UserProfile profile) async {
      profiles.profile = profile;
      final principal = await resolver.resolve(token, 'jwt');
      return accounts.byId[principal.accountId.value]!;
    }

    test(
      'split the full name when given and family names are missing',
      () async {
        final account = await register(
          const UserProfile(name: 'Grace Brewster Hopper'),
        );

        expect(account.firstName, 'Grace');
        expect(account.lastName, 'Brewster Hopper');
      },
    );

    test('fall back to the email name for a password sign-up', () async {
      final account = await register(
        const UserProfile(name: 'sam@example.com', email: 'sam@example.com'),
      );

      expect(account.firstName, 'sam');
      expect(account.lastName, 'Unknown');
    });

    test('fall back to placeholders when the profile is empty', () async {
      final account = await register(const UserProfile());

      expect(account.firstName, 'New user');
      expect(account.lastName, 'Unknown');
      expect(account.email, isNull);
    });
  });

  test('refuses an archived account', () async {
    final principal = await resolver.resolve(token, 'jwt');
    final account = accounts.byId[principal.accountId.value]!;
    accounts.byId[account.id.value] = Account(
      id: account.id,
      firstName: account.firstName,
      lastName: account.lastName,
      email: account.email,
      kind: AccountKind.registered,
      status: AccountStatus.archived,
      archivedAt: DateTime.utc(2026, 10, 13),
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );

    await expectLater(
      resolver.resolve(token, 'jwt'),
      throwsA(
        isA<ForbiddenError>().having(
          (e) => e.code,
          'code',
          'account_not_active',
        ),
      ),
    );
  });

  test('passes on a profile outage and registers nothing', () async {
    profiles.profile = null;

    await expectLater(
      resolver.resolve(token, 'jwt'),
      throwsA(isA<UserProfileUnavailableException>()),
    );
    expect(accounts.byId, isEmpty);
    expect(identities.byId, isEmpty);
  });

  test('a lost race for the same identity resolves to the winner', () async {
    final winner = AccountIdentity(
      id: Id.create(),
      accountId: Id.create(),
      issuer: token.issuer,
      subject: token.subject,
      createdAt: DateTime.utc(2026, 10, 13),
    );
    identities.beforeSave = () => identities.byId[winner.id.value] = winner;
    accounts.byId[winner.accountId.value] = Account(
      id: winner.accountId,
      firstName: 'Ada',
      lastName: 'Lovelace',
      kind: AccountKind.registered,
      createdAt: DateTime.utc(2026, 10, 13),
      updatedAt: DateTime.utc(2026, 10, 13),
    );

    final principal = await resolver.resolve(token, 'jwt');

    expect(principal.accountId, winner.accountId);
  });
}
