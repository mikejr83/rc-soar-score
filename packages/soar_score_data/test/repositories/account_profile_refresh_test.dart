import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late core.AccountRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    repo = Repository(inst.db).accountRepository;
  });
  tearDown(() => inst.close());

  final t0 = DateTime.utc(2026, 11, 1, 12);

  core.Account account(String email, {DateTime? refreshedAt}) => core.Account(
    id: core.Id.create(),
    firstName: 'Alex',
    lastName: 'Kim',
    email: email,
    kind: core.AccountKind.registered,
    profileRefreshedAt: refreshedAt,
    createdAt: t0,
    updatedAt: t0,
  );

  group('save', () {
    test('a full-row save from an older read keeps a later refresh', () async {
      final read = await repo.save(account('alex@example.org'));
      final at = t0.add(const Duration(minutes: 11));
      await repo.claimProfileRefresh(read.id, expected: null, at: at);

      // A request that read the account before the claim saves it whole.
      await repo.save(read);

      expect((await repo.findById(read.id))!.profileRefreshedAt, at);
    });

    test('a newer refresh time in the saved account is kept', () async {
      final read = await repo.save(
        account('alex@example.org', refreshedAt: t0),
      );
      final later = t0.add(const Duration(hours: 1));

      final saved = await repo.save(
        core.Account.fromJson({
          ...read.toJson(),
          'profile_refreshed_at': later.toIso8601String(),
        }),
      );

      expect(saved.profileRefreshedAt, later);
      expect((await repo.findById(read.id))!.profileRefreshedAt, later);
    });
  });

  group('claimProfileRefresh', () {
    test('only one claim of the same stored value wins', () async {
      final a = await repo.save(account('alex@example.org'));
      final at = t0.add(const Duration(minutes: 11));

      expect(
        await repo.claimProfileRefresh(a.id, expected: null, at: at),
        true,
      );
      expect(
        await repo.claimProfileRefresh(a.id, expected: null, at: at),
        false,
      );
      expect((await repo.findById(a.id))!.profileRefreshedAt, at);

      final later = at.add(const Duration(minutes: 11));
      expect(
        await repo.claimProfileRefresh(a.id, expected: at, at: later),
        true,
      );
      expect(
        await repo.claimProfileRefresh(a.id, expected: at, at: later),
        false,
      );
      expect((await repo.findById(a.id))!.profileRefreshedAt, later);
    });

    test('compares sub-second instants exactly', () async {
      final a = await repo.save(account('alex@example.org'));
      final first = t0.add(
        const Duration(milliseconds: 1234, microseconds: 56),
      );
      final second = first.add(const Duration(minutes: 11, microseconds: 7));

      expect(
        await repo.claimProfileRefresh(a.id, expected: null, at: first),
        true,
      );
      final read = (await repo.findById(a.id))!.profileRefreshedAt;
      expect(read, first);

      // A stale value that differs by one microsecond loses.
      expect(
        await repo.claimProfileRefresh(
          a.id,
          expected: first.add(const Duration(microseconds: 1)),
          at: second,
        ),
        false,
      );
      // The value read back wins, once.
      expect(
        await repo.claimProfileRefresh(a.id, expected: read, at: second),
        true,
      );
      expect(
        await repo.claimProfileRefresh(a.id, expected: read, at: second),
        false,
      );
      expect((await repo.findById(a.id))!.profileRefreshedAt, second);
    });

    test('an unknown account is not claimed', () async {
      expect(
        await repo.claimProfileRefresh(
          core.Id.create(),
          expected: null,
          at: t0,
        ),
        false,
      );
    });
  });

  group('applyProfile', () {
    test('changes the profile columns and nothing else', () async {
      final a = await repo.save(
        core.Account.fromJson({
          ...account('alex@example.org').toJson(),
          'preferred_time_zone': 'Europe/Rome',
        }),
      );
      final now = t0.add(const Duration(hours: 1));

      final applied = await repo.applyProfile(
        a.id,
        firstName: 'Alexis',
        lastName: 'Kimura',
        email: 'Alexis@Example.org',
        emailVerified: true,
        now: now,
      );

      expect(applied, isTrue);
      final stored = (await repo.findById(a.id))!;
      expect(stored.firstName, 'Alexis');
      expect(stored.lastName, 'Kimura');
      expect(stored.email, 'alexis@example.org');
      expect(stored.emailVerified, isTrue);
      expect(stored.updatedAt, now);
      expect(stored.preferredTimeZone, 'Europe/Rome');
      expect(stored.profileRefreshedAt, isNull);
    });

    test('refuses an email another account holds', () async {
      await repo.save(account('taken@example.org'));
      final a = await repo.save(account('alex@example.org'));

      await expectLater(
        repo.applyProfile(
          a.id,
          firstName: 'Alex',
          lastName: 'Kim',
          email: 'taken@example.org',
          emailVerified: true,
          now: t0,
        ),
        throwsA(anything),
      );
      expect((await repo.findById(a.id))!.email, 'alex@example.org');
    });

    test('an unknown account is not changed', () async {
      expect(
        await repo.applyProfile(
          core.Id.create(),
          firstName: 'A',
          lastName: 'B',
          email: null,
          emailVerified: false,
          now: t0,
        ),
        isFalse,
      );
    });
  });
}
