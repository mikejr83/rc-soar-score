import 'package:drift/native.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  group('SoarScoreDatabase (SQLite repository)', () {
    late SoarScoreDatabase db;
    late core.ContestRepository repo;

    setUp(() {
      db = SoarScoreDatabase(NativeDatabase.memory());
      repo = ContestRepository(db);
    });

    tearDown(() async {
      await repo.close();
    });

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

    test('save then findById round-trips the domain type', () async {
      final saved = await repo.save(makeContest());
      final loaded = await repo.findById(saved.id);
      expect(loaded, isNotNull);
      expect(loaded, saved);
    });

    test('findById returns null for unknown ids', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('getAll returns every stored contest', () async {
      final first = await repo.save(makeContest(name: 'First'));
      final second = await repo.save(makeContest(name: 'Second'));
      expect(await repo.getAll(), unorderedEquals([first, second]));
    });

    test('save updates the existing row for the same id', () async {
      final original = makeContest();
      await repo.save(original);
      final updated = core.Contest(
        id: original.id,
        name: 'Renamed',
        startDateTime: original.startDateTime,
        endDateTime: original.endDateTime,
        timezone: original.timezone,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );
      await repo.save(updated);
      expect(await repo.getAll(), [updated]);
      expect((await repo.findById(updated.id))?.name, 'Renamed');
    });

    test('startDateTime is stored and read back in UTC', () async {
      final localStart = DateTime(2026, 4, 15, 10, 30);
      final saved = await repo.save(makeContest(startDateTime: localStart));
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
      await repo.save(full);
      expect(await repo.findById(full.id), full);
    });

    test('delete removes the row and reports accordingly', () async {
      final saved = await repo.save(makeContest());
      expect(await repo.delete(saved.id), isTrue);
      expect(await repo.delete(saved.id), isFalse);
      expect(await repo.findById(saved.id), isNull);
    });
  });
}
