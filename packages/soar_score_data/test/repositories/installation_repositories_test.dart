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

  final installation = core.Installation.fromJson(
    exampleRows('installation').single,
  );

  core.Installation otherInstallation() => core.Installation(
    id: core.Id.create(),
    ownerAccountId: installation.ownerAccountId,
    label: 'Tablet',
    platform: core.Platform.web,
    createdAt: DateTime.utc(2026, 10, 2),
  );

  group('InstallationRepository', () {
    late core.InstallationRepository repo;
    setUp(() => repo = repository.installationRepository);

    test('reads back the example installation unchanged', () async {
      expect(await repo.findById(installation.id), installation);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists the installations of an account', () async {
      final tablet = otherInstallation();
      await repo.save(tablet);

      final listed = await repo.listForAccount(installation.ownerAccountId);

      expect(listed, unorderedEquals([installation, tablet]));
      expect(await repo.listForAccount(core.Id.create()), isEmpty);
    });

    test('revoking is a save and records no mutation', () async {
      final before = await inst.count('mutation_records');
      final revoked = core.Installation.fromJson({
        ...installation.toJson(),
        'revoked_at': '2026-10-18T09:00:00Z',
      });

      await repo.save(revoked);

      final stored = await repo.findById(installation.id);
      expect(stored, revoked);
      expect(stored!.isRevoked, isTrue);
      expect(await inst.count('mutation_records'), before);
    });

    test('remove reports whether the installation existed', () async {
      final tablet = otherInstallation();
      await repo.save(tablet);

      expect(await repo.remove(tablet.id), isTrue);
      expect(await repo.findById(tablet.id), isNull);
      expect(await repo.remove(tablet.id), isFalse);
    });

    test('the database refuses an unknown owner account', () async {
      final orphan = core.Installation(
        id: core.Id.create(),
        ownerAccountId: core.Id.create(),
        label: 'Ghost',
        platform: core.Platform.windows,
        createdAt: DateTime.utc(2026, 10, 2),
      );

      await expectLater(repo.save(orphan), throwsA(anything));
    });
  });

  group('InstallationActivationRepository', () {
    late core.InstallationActivationRepository repo;
    setUp(() => repo = repository.installationActivationRepository);

    final activation = core.InstallationActivation.fromJson(
      exampleRows('installation_activation').single,
    );

    test('reads back the example activation unchanged', () async {
      expect(await repo.findById(activation.id), activation);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists by contest and by installation', () async {
      expect(await repo.listForContest(activation.contestId), [activation]);
      expect(await repo.listForContest(core.Id.create()), isEmpty);
      expect(await repo.listForInstallation(activation.installationId), [
        activation,
      ]);
      expect(await repo.listForInstallation(core.Id.create()), isEmpty);
    });

    test('finds the open activation until it is closed', () async {
      Future<core.InstallationActivation?> open() => repo.findOpen(
        contestId: activation.contestId,
        installationId: activation.installationId,
      );

      expect(await open(), activation);

      final closed = activation.close(DateTime.utc(2026, 10, 18));
      await repo.save(closed);

      expect(await repo.findById(activation.id), closed);
      expect(await open(), isNull);
      expect(await repo.listForContest(activation.contestId), [closed]);
    });

    test('remove reports whether the activation existed', () async {
      expect(await repo.remove(activation.id), isTrue);
      expect(await repo.remove(activation.id), isFalse);
    });

    test('the database refuses an unknown installation', () async {
      final orphan = core.InstallationActivation(
        id: core.Id.create(),
        contestId: activation.contestId,
        installationId: core.Id.create(),
        activatedBy: activation.activatedBy,
        kind: activation.kind,
        activatedAt: DateTime.utc(2026, 10, 2),
      );

      await expectLater(repo.save(orphan), throwsA(anything));
    });
  });

  group('SyncCursorRepository', () {
    late core.SyncCursorRepository repo;
    setUp(() => repo = repository.syncCursorRepository);

    final cursor = core.SyncCursor.fromJson(exampleRows('sync_cursor').single);

    core.SyncCursor ownerCursor() => core.SyncCursor(
      id: core.Id.create(),
      installationId: cursor.installationId,
      ownerAccountId: installation.ownerAccountId,
      lastSyncedSequence: 7,
      updatedAt: DateTime.utc(2026, 10, 2),
    );

    test('reads back the example cursor unchanged', () async {
      expect(await repo.findById(cursor.id), cursor);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds the cursor of a contest', () async {
      expect(
        await repo.findForContest(
          installationId: cursor.installationId,
          contestId: cursor.contestId!,
        ),
        cursor,
      );
      expect(
        await repo.findForContest(
          installationId: cursor.installationId,
          contestId: core.Id.create(),
        ),
        isNull,
      );
    });

    test('finds the cursor of the owner system data', () async {
      final owner = ownerCursor();
      await repo.save(owner);

      expect(
        await repo.findForOwner(
          installationId: cursor.installationId,
          ownerAccountId: owner.ownerAccountId!,
        ),
        owner,
      );
      expect(
        await repo.findForOwner(
          installationId: cursor.installationId,
          ownerAccountId: core.Id.create(),
        ),
        isNull,
      );
    });

    test('lists the cursors of an installation', () async {
      final owner = ownerCursor();
      await repo.save(owner);

      expect(
        await repo.listForInstallation(cursor.installationId),
        unorderedEquals([cursor, owner]),
      );
      expect(await repo.listForInstallation(core.Id.create()), isEmpty);
    });

    test('save advances the cursor in place', () async {
      final advanced = core.SyncCursor.fromJson({
        ...cursor.toJson(),
        'last_synced_sequence': 500,
      });

      await repo.save(advanced);

      expect(await repo.findById(cursor.id), advanced);
      expect(await repo.listForInstallation(cursor.installationId), [advanced]);
    });

    test('the database refuses a second cursor for the same scope', () async {
      final repeated = core.SyncCursor(
        id: core.Id.create(),
        installationId: cursor.installationId,
        contestId: cursor.contestId,
        updatedAt: DateTime.utc(2026, 10, 2),
      );

      await expectLater(repo.save(repeated), throwsA(anything));
    });

    test('remove reports whether the cursor existed', () async {
      expect(await repo.remove(cursor.id), isTrue);
      expect(await repo.remove(cursor.id), isFalse);
    });
  });
}
