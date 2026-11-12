import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  group('ContestRepository', () {
    late Installation inst;
    late core.ContestRepository repo;

    setUp(() async {
      inst = await Installation.open(backend);
      repo = ContestRepository(inst.db);
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 4, 1),
    );
    Future<core.Contest> save(core.Contest contest) =>
        repo.save(contest, metadata: meta());
    Future<bool> delete(core.Id id) => repo.delete(id, metadata: meta());

    core.Contest makeContest({
      String? name,
      DateTime? startDateTime,
      core.LifecycleState lifecycleState = core.LifecycleState.created,
    }) => core.Contest(
      id: core.Id.create(),
      name: name ?? 'Spring Meet',
      startDateTime: startDateTime ?? DateTime.utc(2026, 4, 15, 10, 30),
      endDateTime: DateTime.utc(2026, 4, 16, 20),
      timezone: 'America/Denver',
      lifecycleState: lifecycleState,
      createdAt: DateTime.utc(2026, 4),
      updatedAt: DateTime.utc(2026, 4),
    );

    test('findByIds takes more ids than one query could bind', () async {
      final first = await save(makeContest(name: 'First'));
      final second = await save(makeContest(name: 'Second'));
      final ids = [
        first.id,
        for (var i = 0; i < 40000; i++) core.Id.create(),
        second.id,
      ];

      final found = await repo.findByIds(ids);

      expect(found.keys, unorderedEquals([first.id, second.id]));
      expect(await repo.findByIds(const []), isEmpty);
    });

    test('save then findById round-trips the domain type', () async {
      final saved = await save(makeContest());
      final loaded = await repo.findById(saved.id);
      expect(loaded, isNotNull);
      expect(loaded, saved);
    });

    test('findById returns null for unknown ids', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('getAll returns every stored contest', () async {
      final first = await save(makeContest(name: 'First'));
      final second = await save(makeContest(name: 'Second'));
      expect(await repo.getAll(), unorderedEquals([first, second]));
    });

    test('save updates the existing row for the same id', () async {
      final original = makeContest();
      await save(original);
      final updated = core.Contest(
        id: original.id,
        name: 'Renamed',
        startDateTime: original.startDateTime,
        endDateTime: original.endDateTime,
        timezone: original.timezone,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );
      final stored = await save(updated);
      expect(stored.revision, 1);
      expect(await repo.getAll(), [stored]);
      expect((await repo.findById(updated.id))?.name, 'Renamed');
    });

    test('startDateTime is stored and read back in UTC', () async {
      final localStart = DateTime(2026, 4, 15, 10, 30);
      final saved = await save(makeContest(startDateTime: localStart));
      final loaded = await repo.findById(saved.id);
      expect(loaded?.startDateTime, saved.startDateTime.toUtc());
      expect(loaded?.startDateTime.isUtc, isTrue);
    });

    test('every field survives a save, including the control states', () async {
      final full = core.Contest(
        id: core.Id.create(),
        name: 'Full',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
        timezone: 'America/Denver',
        host: 'Front Range Soaring Society',
        city: 'Boulder',
        state: 'CO',
        country: 'USA',
        ownerAccountId: core.Id.create(),
        lifecycleState: core.LifecycleState.running,
        scoringAccess: core.ScoringAccess.open,
        adminLock: core.AdminLock.locked,
        resultsHiddenThroughRound: 2,
        resultsHiddenAt: DateTime.utc(2026, 10, 17, 18),
        localArchive: true,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 10, 17, 15, 10),
        revision: 7,
      );
      await save(full);
      expect(await repo.findById(full.id), full);
    });

    test('delete removes the row and reports accordingly', () async {
      final saved = await save(makeContest());
      expect(await delete(saved.id), isTrue);
      expect(await delete(saved.id), isFalse);
      expect(await repo.findById(saved.id), isNull);
    });
  });
}
