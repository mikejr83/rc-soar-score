import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data_sqlite/soar_score_data_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('ContestSqliteRepository', () {
    late ContestDatabase database;
    late ContestSqliteRepository repository;

    setUp(() {
      database = ContestDatabase.inMemory();
      repository = ContestSqliteRepository(database);
    });

    tearDown(() async {
      await repository.close();
    });

    Contest makeContest({String? name, DateTime? startedAt}) => Contest(
          id: Id.create(),
          name: name ?? 'Spring Meet',
          startedAt: startedAt ?? DateTime.utc(2026, 4, 15, 10, 30),
        );

    test('save then findById round-trips the domain type', () async {
      final saved = await repository.save(makeContest());

      final loaded = await repository.findById(saved.id);
      expect(loaded, isNotNull);
      expect(loaded, saved);
    });

    test('findById returns null for unknown ids', () async {
      expect(await repository.findById(Id.create()), isNull);
    });

    test('getAll returns every stored contest', () async {
      final first = await repository.save(makeContest(name: 'First'));
      final second = await repository.save(makeContest(name: 'Second'));

      expect(await repository.getAll(), unorderedEquals([first, second]));
    });

    test('save updates the existing row for the same id', () async {
      final original = makeContest();
      await repository.save(original);

      final updated = Contest(
        id: original.id,
        name: 'Renamed',
        startedAt: original.startedAt,
      );
      await repository.save(updated);

      expect(await repository.getAll(), [updated]);
      expect((await repository.findById(updated.id))?.name, 'Renamed');
    });

    test('startedAt is stored and read back in UTC', () async {
      final localStart = DateTime(2026, 4, 15, 10, 30);
      final saved = await repository.save(makeContest(startedAt: localStart));

      final loaded = await repository.findById(saved.id);
      expect(loaded?.startedAt, saved.startedAt.toUtc());
      expect(loaded?.startedAt.isUtc, isTrue);
    });

    test('delete removes the row and reports accordingly', () async {
      final saved = await repository.save(makeContest());

      expect(await repository.delete(saved.id), isTrue);
      expect(await repository.delete(saved.id), isFalse);
      expect(await repository.findById(saved.id), isNull);
    });
  });
}
