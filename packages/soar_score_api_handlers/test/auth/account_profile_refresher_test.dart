import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fake_account_repositories.dart';

class _Profiles implements UserProfileSource {
  UserProfile? profile;
  Future<UserProfile> Function()? slow;
  int fetches = 0;

  @override
  Future<UserProfile> fetch(String accessToken) async {
    fetches++;
    if (slow != null) return slow!();
    return profile ?? (throw const UserProfileUnavailableException('down'));
  }
}

void main() {
  late FakeAccountRepository accounts;
  late _Profiles profiles;
  late DateTime clock;
  late AccountProfileRefresher refresher;
  final start = DateTime.utc(2026, 11, 1, 12);

  Account account({
    String? email = 'ada@example.com',
    bool verified = false,
    DateTime? refreshedAt,
    AccountKind kind = AccountKind.registered,
  }) => Account(
    id: Id.create(),
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: kind == AccountKind.registered ? email : null,
    emailVerified: verified,
    kind: kind,
    profileRefreshedAt: refreshedAt,
    createdAt: start,
    updatedAt: start,
  );

  Future<Account> store(Account a) async {
    accounts.byId[a.id.value] = a;
    return a;
  }

  Account stored(Account a) => accounts.byId[a.id.value]!;

  setUp(() {
    accounts = FakeAccountRepository();
    profiles = _Profiles();
    clock = start.add(const Duration(minutes: 30));
    refresher = AccountProfileRefresher(
      accounts: accounts,
      profiles: profiles,
      now: () => clock,
      timeout: const Duration(milliseconds: 50),
    );
  });

  test(
    'sets the verified flag once the person verified at the provider',
    () async {
      final a = await store(account(refreshedAt: start));
      profiles.profile = const UserProfile(
        givenName: 'Ada',
        familyName: 'Lovelace',
        email: 'ada@example.com',
        emailVerified: true,
      );

      await refresher.refresh(a, 'jwt');

      expect(stored(a).emailVerified, isTrue);
      expect(stored(a).profileRefreshedAt, clock);
      expect(profiles.fetches, 1);
    },
  );

  test('an account never refreshed is refreshed on the next request', () async {
    final a = await store(account());
    profiles.profile = const UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: 'ada@example.com',
      emailVerified: true,
    );

    await refresher.refresh(a, 'jwt');

    expect(stored(a).emailVerified, isTrue);
  });

  test('asks at most once per ten minutes, verified or not', () async {
    final a = await store(
      account(refreshedAt: clock.subtract(const Duration(minutes: 9))),
    );
    profiles.profile = const UserProfile(email: 'ada@example.com');

    await refresher.refresh(a, 'jwt');

    expect(profiles.fetches, 0);
    expect(stored(a).profileRefreshedAt, a.profileRefreshedAt);
  });

  test('a verified account is asked again only after 24 hours', () async {
    final recent = await store(
      account(
        verified: true,
        refreshedAt: clock.subtract(const Duration(hours: 23)),
      ),
    );
    final old = await store(
      account(
        email: 'old@example.com',
        verified: true,
        refreshedAt: clock.subtract(const Duration(hours: 25)),
      ),
    );
    profiles.profile = const UserProfile(
      email: 'ada@example.com',
      emailVerified: true,
    );

    await refresher.refresh(recent, 'jwt');
    expect(profiles.fetches, 0);
    await refresher.refresh(old, 'jwt');
    expect(profiles.fetches, 1);
  });

  test('a changed email updates the account and its flag', () async {
    final a = await store(account(verified: true, refreshedAt: start));
    profiles.profile = const UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: 'New@Example.com',
    );
    clock = start.add(const Duration(hours: 25));

    await refresher.refresh(a, 'jwt');

    expect(stored(a).email, 'new@example.com');
    expect(stored(a).emailVerified, isFalse);
  });

  test('an email another account holds changes nothing', () async {
    final other = await store(account(email: 'taken@example.com'));
    final a = await store(account(verified: false, refreshedAt: start));
    profiles.profile = UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: other.email,
      emailVerified: true,
    );

    await refresher.refresh(a, 'jwt');

    expect(stored(a).email, 'ada@example.com');
    expect(stored(a).emailVerified, isFalse);
  });

  test('losing the email race at the write keeps the old email', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = const UserProfile(
      givenName: 'Grace',
      familyName: 'Hopper',
      email: 'race@example.com',
      emailVerified: true,
    );
    // Another account takes the email after the refresher's check.
    final racing = _RacingAccounts(accounts, 'race@example.com');
    final racer = AccountProfileRefresher(
      accounts: racing,
      profiles: profiles,
      now: () => clock,
    );

    await racer.refresh(a, 'jwt');

    final after = racing.byId[a.id.value]!;
    expect(after.email, 'ada@example.com');
    expect(after.emailVerified, isFalse);
    expect(after.firstName, 'Grace');
  });

  test('uses the stored values when the provider is down', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = null;

    await refresher.refresh(a, 'jwt');

    expect(stored(a).email, 'ada@example.com');
    expect(stored(a).emailVerified, isFalse);
  });

  test('uses the stored values when the provider is slow', () async {
    final a = await store(account(refreshedAt: start));
    profiles.slow = () =>
        Future.delayed(const Duration(seconds: 5), () => const UserProfile());

    await refresher.refresh(a, 'jwt');

    expect(stored(a).email, 'ada@example.com');
  });

  test('concurrent refreshes ask the provider once', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = const UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: 'ada@example.com',
      emailVerified: true,
    );

    await Future.wait([
      refresher.refresh(a, 'jwt'),
      refresher.refresh(a, 'jwt'),
    ]);

    expect(profiles.fetches, 1);
    expect(stored(a).emailVerified, isTrue);
  });

  test('a request that loses the claim leaves the account alone', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = const UserProfile(email: 'ada@example.com');
    accounts.beforeClaim = () {
      accounts.beforeClaim = null;
      accounts.claimProfileRefresh(a.id, expected: start, at: clock);
    };

    await refresher.refresh(a, 'jwt');

    expect(profiles.fetches, 0);
  });

  test('a given name alone keeps the stored last name', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = const UserProfile(
      givenName: 'Augusta',
      email: 'ada@example.com',
      emailVerified: true,
    );

    await refresher.refresh(a, 'jwt');

    expect(stored(a).firstName, 'Augusta');
    expect(stored(a).lastName, 'Lovelace');
  });

  test('a provider that is down does not shut a verified account out for '
      'a day', () async {
    final a = await store(
      account(verified: true, refreshedAt: start, email: 'ada@example.com'),
    );
    clock = start.add(const Duration(hours: 25));
    profiles.profile = null;

    await refresher.refresh(a, 'jwt');
    expect(profiles.fetches, 1);

    // Not again straight away, but after the ten-minute minimum.
    clock = clock.add(const Duration(minutes: 5));
    await refresher.refresh(stored(a), 'jwt');
    expect(profiles.fetches, 1);

    clock = clock.add(const Duration(minutes: 6));
    profiles.profile = const UserProfile(
      givenName: 'Ada',
      familyName: 'Lovelace',
      email: 'ada@example.com',
      emailVerified: true,
    );
    await refresher.refresh(stored(a), 'jwt');
    expect(profiles.fetches, 2);
    expect(stored(a).profileRefreshedAt, clock);
  });

  test('keeps the stored name when the provider gives none', () async {
    final a = await store(account(refreshedAt: start));
    profiles.profile = const UserProfile(
      name: 'ada@example.com',
      email: 'ada@example.com',
      emailVerified: true,
    );

    await refresher.refresh(a, 'jwt');

    expect(stored(a).firstName, 'Ada');
    expect(stored(a).lastName, 'Lovelace');
    expect(stored(a).emailVerified, isTrue);
  });

  test(
    'a stale verified account with an unchanged profile only restamps',
    () async {
      final a = await store(
        account(
          verified: true,
          refreshedAt: clock.subtract(const Duration(hours: 25)),
        ),
      );
      profiles.profile = const UserProfile(
        givenName: 'Ada',
        familyName: 'Lovelace',
        email: 'ada@example.com',
        emailVerified: true,
      );

      await refresher.refresh(a, 'jwt');

      expect(profiles.fetches, 1);
      expect(stored(a).profileRefreshedAt, clock);
      expect(stored(a).updatedAt, a.updatedAt);
      expect(stored(a).email, 'ada@example.com');
    },
  );

  test(
    'an email missing at the provider keeps the stored email and flag',
    () async {
      final a = await store(account(verified: true, refreshedAt: start));
      profiles.profile = const UserProfile(
        givenName: 'Ada',
        familyName: 'Lovelace',
      );
      clock = start.add(const Duration(hours: 25));

      await refresher.refresh(a, 'jwt');

      expect(stored(a).email, 'ada@example.com');
      expect(stored(a).emailVerified, isTrue);
    },
  );

  test('never refreshes a guest, local or deleted account', () async {
    profiles.profile = const UserProfile(email: 'x@example.com');
    for (final kind in [
      AccountKind.guest,
      AccountKind.local,
      AccountKind.deleted,
    ]) {
      await refresher.refresh(await store(account(kind: kind)), 'jwt');
    }

    expect(profiles.fetches, 0);
  });
}

/// Reports no holder for [email] and then refuses to store it, as a database
/// does when another account took it in between.
class _RacingAccounts extends FakeAccountRepository {
  _RacingAccounts(FakeAccountRepository inner, this.email) {
    byId.addAll(inner.byId);
  }

  final String email;
  int applies = 0;

  @override
  Future<Account?> findByEmail(String email) async => null;

  @override
  Future<bool> applyProfile(
    Id id, {
    required String firstName,
    required String lastName,
    required String? email,
    required bool emailVerified,
    required DateTime now,
  }) {
    applies++;
    if (email == this.email) throw StateError('duplicate email');
    return super.applyProfile(
      id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      emailVerified: emailVerified,
      now: now,
    );
  }
}
