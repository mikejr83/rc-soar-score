import 'package:test/test.dart';

import '../support/example_files.dart';
import '../support/registered_examples.dart';

/// Round-trips every row in `plan/data-model/examples/entities/<entity>.json`
/// through its model: `toJson(fromJson(row))` must equal the row, which
/// catches missing fields, renamed keys, dropped nulls and enum casing.
///
/// Entities without a registered model are skipped, visibly. Each model PR
/// registers its entities in `test/support/registered_examples.dart` until no
/// skips remain.
void main() {
  final files = ExampleFiles.locate();
  final catalog = files.catalog();
  final registry = buildExampleRegistry();

  test('the catalog lists 50 distinct entities and files', () {
    expect(catalog.map((e) => e.entity).toSet(), hasLength(50));
    expect(catalog.map((e) => e.stem).toSet(), hasLength(50));
  });

  test('every catalog entity has an example file and none is stray', () {
    expect(files.exampleStems(), equals(catalog.map((e) => e.stem).toSet()));
  });

  test('every example file is a non-empty array of objects', () {
    for (final entry in catalog) {
      expect(files.rows(entry), isNotEmpty, reason: entry.stem);
    }
  });

  test('every catalog entity has a registered model', () {
    expect(
      catalog
          .map((e) => e.entity)
          .toSet()
          .difference(registry.entities.toSet()),
      isEmpty,
    );
  });

  test('every registered entity is a catalog entity', () {
    expect(
      registry.entities.toSet().difference(
        catalog.map((e) => e.entity).toSet(),
      ),
      isEmpty,
    );
  });

  group('round trip', () {
    for (final entry in catalog) {
      final roundTrip = registry[entry.entity];
      test(entry.entity, () {
        for (final row in files.rows(entry)) {
          expect(roundTrip!(row.json), equals(row.json), reason: '$row');
        }
      }, skip: roundTrip == null ? 'no model registered yet' : false);
    }
  });
}
