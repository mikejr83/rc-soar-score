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

  final accountIds = [
    for (final row in exampleRows('account'))
      core.Id.parse(row['id']! as String),
  ];

  group('ParticipantAccountLinkRepository', () {
    late core.ParticipantAccountLinkRepository repo;
    setUp(() => repo = repository.participantAccountLinkRepository);

    final link = core.ParticipantAccountLink.fromJson(
      exampleRows('participant_account_link').single,
    );

    core.ParticipantAccountLink candidate(core.Id accountId) =>
        core.ParticipantAccountLink(
          id: core.Id.create(),
          participantProfileId: link.participantProfileId,
          accountId: accountId,
          status: core.ParticipantLinkStatus.candidate,
          origin: core.ParticipantLinkOrigin.emailMatch,
          createdAt: DateTime.utc(2026, 10, 3),
        );

    test('reads back the example link unchanged', () async {
      expect(await repo.findById(link.id), link);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds by profile and account, and lists either side', () async {
      expect(
        await repo.find(
          participantProfileId: link.participantProfileId,
          accountId: link.accountId,
        ),
        link,
      );
      expect(
        await repo.find(
          participantProfileId: link.participantProfileId,
          accountId: accountIds.first,
        ),
        isNull,
      );
      expect(await repo.listForProfile(link.participantProfileId), [link]);
      expect(await repo.listForAccount(link.accountId), [link]);
      expect(await repo.listForAccount(core.Id.create()), isEmpty);
    });

    test('finds the confirmed link of a profile', () async {
      expect(
        await repo.findConfirmedForProfile(link.participantProfileId),
        link,
      );

      await repo.save(candidate(accountIds.first));

      expect(
        await repo.findConfirmedForProfile(link.participantProfileId),
        link,
      );
      expect(await repo.findConfirmedForProfile(core.Id.create()), isNull);
    });

    test('save bumps the revision and records no mutation', () async {
      final before = await inst.count('mutation_records');
      final ended = core.ParticipantAccountLink.fromJson({
        ...link.toJson(),
        'status': 'Ended',
        'ended_at': '2026-10-04T10:00:00Z',
      });

      final saved = await repo.save(ended);

      expect(saved.revision, link.revision + 1);
      expect(saved.status, core.ParticipantLinkStatus.ended);
      expect(await repo.findById(link.id), saved);
      expect(await inst.count('mutation_records'), before);
    });

    test('save of a new link keeps the revision it carries', () async {
      final fresh = candidate(accountIds.first);

      expect(await repo.save(fresh), fresh);
      expect(await repo.findById(fresh.id), fresh);
    });

    test('save of a link read at an older revision is stale', () async {
      await repo.save(link);

      await expectLater(
        repo.save(link),
        throwsA(
          isA<core.StaleRevisionError>()
              .having((e) => e.expectedRevision, 'expected', 2)
              .having((e) => e.storedRevision, 'stored', 3),
        ),
      );
      expect((await repo.findById(link.id))!.revision, 3);
    });

    test(
      'the database refuses a second confirmed link for a profile',
      () async {
        final second = core.ParticipantAccountLink.fromJson({
          ...candidate(accountIds.first).toJson(),
          'status': 'Confirmed',
          'confirmed_at': '2026-10-03T10:00:00Z',
        });

        await expectLater(repo.save(second), throwsA(anything));
      },
    );

    test('the database refuses a repeated profile and account', () async {
      await expectLater(
        repo.save(candidate(link.accountId)),
        throwsA(anything),
      );
    });
  });

  group('ParticipantDirectoryEntryRepository', () {
    late core.ParticipantDirectoryEntryRepository repo;
    setUp(() => repo = repository.participantDirectoryEntryRepository);

    final entry = core.ParticipantDirectoryEntry.fromJson(
      exampleRows('participant_directory_entry').single,
    );

    core.ParticipantDirectoryEntry other(
      core.Id accountId, {
      bool isListed = true,
    }) => core.ParticipantDirectoryEntry(
      id: core.Id.create(),
      accountId: accountId,
      firstName: 'Dana',
      lastName: 'Whitfield',
      isListed: isListed,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    test('reads back the example entry unchanged', () async {
      expect(await repo.findById(entry.id), entry);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds the entry of an account', () async {
      expect(await repo.findForAccount(entry.accountId), entry);
      expect(await repo.findForAccount(accountIds.first), isNull);
    });

    test('lists only the entries their owners chose to list', () async {
      final hidden = other(accountIds.first, isListed: false);
      await repo.save(hidden);

      expect(await repo.listListed(), [entry]);

      final shown = core.ParticipantDirectoryEntry.fromJson({
        ...hidden.toJson(),
        'is_listed': true,
      });
      await repo.save(shown);

      expect((await repo.listListed()).map((e) => e.id).toSet(), {
        entry.id,
        shown.id,
      });
    });

    test('save replaces the entry without a mutation record', () async {
      final before = await inst.count('mutation_records');
      final moved = core.ParticipantDirectoryEntry.fromJson({
        ...entry.toJson(),
        'city': 'Denver',
      });

      await repo.save(moved);

      expect(await repo.findById(entry.id), moved);
      expect(await inst.count('mutation_records'), before);
    });

    test('the database refuses a second entry for an account', () async {
      await expectLater(repo.save(other(entry.accountId)), throwsA(anything));
    });

    test('remove deletes the entry and reports whether it existed', () async {
      expect(await repo.remove(entry.id), isTrue);
      expect(await repo.findForAccount(entry.accountId), isNull);
      expect(await repo.remove(entry.id), isFalse);
    });
  });
}
