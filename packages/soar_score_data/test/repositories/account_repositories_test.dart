import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forPostgresOnly(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  final accounts = [
    for (final row in exampleRows('account')) core.Account.fromJson(row),
  ];
  final dana = accounts.first;

  core.Account newAccount({
    String? email,
    core.AccountKind kind = core.AccountKind.registered,
  }) => core.Account(
    id: core.Id.create(),
    firstName: 'Alex',
    lastName: 'Kim',
    email: email,
    kind: kind,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  group('AccountRepository', () {
    late core.AccountRepository repo;
    setUp(() => repo = repository.accountRepository);

    test('reads back every example account unchanged', () async {
      for (final account in accounts) {
        expect(await repo.findById(account.id), account);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds by email ignoring case', () async {
      expect(await repo.findByEmail('Dana@Example.org'), dana);
      expect(await repo.findByEmail(' dana@example.org '), dana);
      expect(await repo.findByEmail('nobody@example.org'), isNull);
    });

    test('finds the deleted-user account once it exists', () async {
      expect(await repo.findDeletedUser(), isNull);

      final deleted = newAccount(kind: core.AccountKind.deleted);
      await repo.save(deleted);

      expect(await repo.findDeletedUser(), deleted);
    });

    test('save inserts, then replaces, without a mutation record', () async {
      final before = await inst.count('mutation_records');
      final fresh = newAccount(email: 'alex@example.org');

      await repo.save(fresh);
      expect(await repo.findById(fresh.id), fresh);

      final renamed = core.Account.fromJson({
        ...fresh.toJson(),
        'first_name': 'Alexis',
      });
      await repo.save(renamed);
      expect(await repo.findById(fresh.id), renamed);
      expect(await inst.count('mutation_records'), before);
    });

    // `accounts` is a backend table: it exists on the server profile only,
    // so this runs on PostgreSQL. The client-side values are tested on SQLite
    // in local_account_repository_test.dart.
    test('stores the preferences with the account', () async {
      expect(dana.preferredTimeZone, 'America/Chicago');
      expect(dana.preferredLocale, 'en-US');
      final service = core.AccountPreferencesService(repository);

      final saved = await service.update(
        accountId: dana.id,
        preferences: core.AccountPreferences(preferredTimeZone: 'Europe/Rome'),
        now: DateTime.utc(2026, 10, 19),
      );

      expect(saved.preferredTimeZone, 'Europe/Rome');
      expect(saved.preferredLocale, isNull);
      expect(await service.get(dana.id), saved);
      expect(
        (await repo.findById(dana.id))?.updatedAt,
        DateTime.utc(2026, 10, 19),
      );
    });

    test('the database refuses a repeated email', () async {
      await expectLater(
        repo.save(newAccount(email: 'sam@example.org')),
        throwsA(anything),
      );
    });

    test('the database refuses a second deleted-user account', () async {
      await repo.save(newAccount(kind: core.AccountKind.deleted));

      await expectLater(
        repo.save(newAccount(kind: core.AccountKind.deleted)),
        throwsA(anything),
      );
    });
  });

  group('AccountIdentityRepository', () {
    late core.AccountIdentityRepository repo;
    setUp(() => repo = repository.accountIdentityRepository);

    final identity = core.AccountIdentity.fromJson(
      exampleRows('account_identity').single,
    );

    test('reads back the example identity unchanged', () async {
      expect(await repo.findById(identity.id), identity);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds by issuer and subject together', () async {
      expect(
        await repo.findBySubject(
          issuer: identity.issuer,
          subject: identity.subject,
        ),
        identity,
      );
      expect(
        await repo.findBySubject(
          issuer: 'https://other.example.com',
          subject: identity.subject,
        ),
        isNull,
      );
    });

    test('lists the identities of an account', () async {
      expect(await repo.listForAccount(identity.accountId), [identity]);
      expect(await repo.listForAccount(core.Id.create()), isEmpty);
    });

    test('the same subject may come from another issuer', () async {
      final other = core.AccountIdentity(
        id: core.Id.create(),
        accountId: accounts[1].id,
        issuer: 'https://other.example.com',
        subject: identity.subject,
        createdAt: DateTime.utc(2026, 10, 2),
      );

      await repo.save(other);

      expect(
        await repo.findBySubject(issuer: other.issuer, subject: other.subject),
        other,
      );
    });

    test('the database refuses a repeated issuer and subject', () async {
      final repeated = core.AccountIdentity(
        id: core.Id.create(),
        accountId: accounts[1].id,
        issuer: identity.issuer,
        subject: identity.subject,
        createdAt: DateTime.utc(2026, 10, 2),
      );

      await expectLater(repo.save(repeated), throwsA(anything));
    });

    test(
      'remove deletes the identity and reports whether it existed',
      () async {
        expect(await repo.remove(identity.id), isTrue);
        expect(await repo.findById(identity.id), isNull);
        expect(await repo.remove(identity.id), isFalse);
      },
    );
  });

  group('AccountAliasRepository', () {
    late core.AccountAliasRepository repo;
    setUp(() => repo = repository.accountAliasRepository);

    final alias = core.AccountAlias.fromJson(
      exampleRows('account_alias').single,
    );
    final claimedAt = DateTime.utc(2026, 10, 13, 12);

    test('reads back the example alias unchanged', () async {
      expect(await repo.findById(alias.id), alias);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists the aliases of an account', () async {
      expect(await repo.listForAccount(alias.accountId), [alias]);
      expect(await repo.listForAccount(core.Id.create()), isEmpty);
    });

    test('claims a Local account id into an account', () async {
      final local = core.Id.create();

      final claimed = await repo.claim(
        localAccountId: local,
        accountId: dana.id,
        claimedAt: claimedAt,
      );

      expect(claimed.id, local);
      expect(claimed.accountId, dana.id);
      expect(claimed.claimedAt, claimedAt);
      expect(await repo.findById(local), claimed);
    });

    test('claiming again for the same account changes nothing', () async {
      final local = core.Id.create();
      final first = await repo.claim(
        localAccountId: local,
        accountId: dana.id,
        claimedAt: claimedAt,
      );

      final again = await repo.claim(
        localAccountId: local,
        accountId: dana.id,
        claimedAt: claimedAt.add(const Duration(days: 1)),
      );

      expect(again, first);
      expect(await repo.listForAccount(dana.id), contains(first));
    });

    test('a claim never moves to another account', () async {
      final local = core.Id.create();
      final first = await repo.claim(
        localAccountId: local,
        accountId: dana.id,
        claimedAt: claimedAt,
      );

      final other = await repo.claim(
        localAccountId: local,
        accountId: accounts[1].id,
        claimedAt: claimedAt,
      );

      expect(other, first);
      expect(other.accountId, dana.id);
    });

    test('one account can hold several aliases', () async {
      final a = core.Id.create();
      final b = core.Id.create();
      await repo.claim(
        localAccountId: a,
        accountId: dana.id,
        claimedAt: claimedAt,
      );
      await repo.claim(
        localAccountId: b,
        accountId: dana.id,
        claimedAt: claimedAt,
      );

      final ids = (await repo.listForAccount(dana.id)).map((x) => x.id);

      expect(ids, containsAll([a, b]));
    });

    test('the database refuses an alias of an unknown account', () async {
      await expectLater(
        repo.claim(
          localAccountId: core.Id.create(),
          accountId: core.Id.create(),
          claimedAt: claimedAt,
        ),
        throwsA(anything),
      );
    });

    test(
      'resolves an alias to its account and any other id to itself',
      () async {
        final unknown = core.Id.create();

        expect(await repo.resolve(alias.id), alias.accountId);
        expect(await repo.resolve(dana.id), dana.id);
        expect(await repo.resolve(unknown), unknown);
      },
    );
  });

  group('AccountPublicProfileRepository', () {
    late core.AccountPublicProfileRepository repo;
    setUp(() => repo = repository.accountPublicProfileRepository);

    final profile = core.AccountPublicProfile.fromJson(
      exampleRows('account_public_profile').single,
    );

    test('reads back the example profile unchanged', () async {
      expect(await repo.findById(profile.id), profile);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds the profile of an account', () async {
      expect(await repo.findForAccount(profile.accountId!), profile);
      expect(await repo.findForAccount(accounts[1].id), isNull);
    });

    test('unlinking keeps the profile and detaches the account', () async {
      final unlinked = core.AccountPublicProfile.fromJson({
        ...profile.toJson(),
        'account_id': null,
      });

      await repo.save(unlinked);

      expect(await repo.findById(profile.id), unlinked);
      expect(await repo.findForAccount(profile.accountId!), isNull);
    });

    test('the database refuses a second profile for an account', () async {
      final second = core.AccountPublicProfile(
        id: core.Id.create(),
        accountId: profile.accountId,
        displayName: 'Dana W.',
        createdAt: DateTime.utc(2026, 10, 1),
      );

      await expectLater(repo.save(second), throwsA(anything));
    });
  });
}
