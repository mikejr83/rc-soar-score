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

    test('F5J matches the plan example', () {
      expect(table.id, SystemLandingTables.f5jStandardId);
      expect([for (final r in results) r.pointValue], [20, 15, 10, 5, 0]);
    });
  });
}
