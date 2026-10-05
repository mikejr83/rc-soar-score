import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final table = SystemLandingTables.f5jStandard.table;
  final results = SystemLandingTables.f5jStandard.results;

  LandingResult entry({Id? tableId, String key = 'extra', int position = 99}) =>
      LandingResult(
        id: Id.create(),
        landingTableId: tableId ?? table.id,
        entryKey: key,
        displayValue: 'Extra',
        pointValue: 1,
        ordinalPosition: position,
      );

  group('LandingTableWithResults', () {
    test('orders the results by position', () {
      final shuffled = LandingTableWithResults(
        table: table,
        results: results.reversed,
      );

      expect(shuffled.results, results);
    });

    test('rejects a table with no results', () {
      expect(
        () => LandingTableWithResults(table: table, results: const []),
        throwsArgumentError,
      );
    });

    test('rejects a result of another table', () {
      expect(
        () => LandingTableWithResults(
          table: table,
          results: [
            ...results,
            entry(tableId: Id.create()),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a repeated entry key or position', () {
      expect(
        () => LandingTableWithResults(
          table: table,
          results: [
            ...results,
            entry(key: results.first.entryKey),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => LandingTableWithResults(
          table: table,
          results: [
            ...results,
            entry(position: results.first.ordinalPosition),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('SystemLandingTables', () {
    test('every table is a system table', () {
      for (final shipped in SystemLandingTables.all) {
        expect(shipped.table.isSystem, isTrue);
      }
    });

    test('the F5J default selects points from 50 down to 0', () {
      expect(table.id, SystemLandingTables.f5jStandardId);
      expect(table.inputUnit, LandingInputUnit.points);
      expect(
        [for (final r in results) r.pointValue],
        [50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 0],
      );
      expect(
        [for (final r in results) r.displayValue],
        [
          '50 pts', '45 pts', '40 pts', '35 pts', '30 pts', '25 pts', //
          '20 pts', '15 pts', '10 pts', '5 pts', '0 pts',
        ],
      );
    });

    test('the F5J distance table maps 1 to 10 meters to 50 to 5', () {
      final distance = SystemLandingTables.f5jDistance;

      expect(distance.table.inputUnit, LandingInputUnit.meters);
      expect(
        [for (final r in distance.results) r.displayValue],
        [
          '1m', '2m', '3m', '4m', '5m', '6m', '7m', '8m', '9m', '10m', //
          'Over 10m',
        ],
      );
      expect(
        [for (final r in distance.results) r.pointValue],
        [50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 0],
      );
    });

    test('table and entry ids are unique across the shipped tables', () {
      final ids = [
        for (final t in SystemLandingTables.all) ...[
          t.table.id,
          ...t.results.map((r) => r.id),
        ],
      ];

      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
