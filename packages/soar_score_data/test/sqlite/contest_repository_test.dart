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

    core.Contest makeContest({String? name, DateTime? startedAt}) =>
        core.Contest(
          id: core.Id.create(),
          name: name ?? 'Spring Meet',
          startedAt: startedAt ?? DateTime.utc(2026, 4, 15, 10, 30),
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
        startedAt: original.startedAt,
      );
      await repo.save(updated);
      expect(await repo.getAll(), [updated]);
      expect((await repo.findById(updated.id))?.name, 'Renamed');
    });

    test('startedAt is stored and read back in UTC', () async {
      final localStart = DateTime(2026, 4, 15, 10, 30);
      final saved = await repo.save(makeContest(startedAt: localStart));
      final loaded = await repo.findById(saved.id);
      expect(loaded?.startedAt, saved.startedAt.toUtc());
      expect(loaded?.startedAt.isUtc, isTrue);
    });

    test('delete removes the row and reports accordingly', () async {
      final saved = await repo.save(makeContest());
      expect(await repo.delete(saved.id), isTrue);
      expect(await repo.delete(saved.id), isFalse);
      expect(await repo.findById(saved.id), isNull);
    });
  });
}
