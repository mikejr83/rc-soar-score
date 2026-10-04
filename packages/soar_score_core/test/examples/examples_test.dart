import 'package:test/test.dart';

import '../support/example_files.dart';
import '../support/registered_examples.dart';

/// Round-trips every example row in `plan/data-model/examples/entities/`
/// through its model: `toJson(fromJson(row))` must equal the row, which
/// catches missing fields, renamed keys, dropped nulls and enum casing.
///
/// Entities without a registered model are skipped, visibly. Each model PR
/// registers its entities in `test/support/registered_examples.dart` until no
/// skips remain.
void main() {
  final files = ExampleFiles.locate();
  final catalog = files.catalogEntities();
  final rows = files.rows();
  final registry = buildExampleRegistry();

  test('the catalog lists all 48 entities', () {
    expect(catalog.toSet(), hasLength(48));
  });

  test('every catalog entity has at least one example row', () {
    final withRows = rows.map((r) => r.entity).toSet();
    expect(catalog.where((e) => !withRows.contains(e)), isEmpty);
  });

  test('every example heading is a catalog entity', () {
    expect(
      rows.map((r) => r.entity).toSet().difference(catalog.toSet()),
      isEmpty,
    );
  });

  test('every registered entity is a catalog entity', () {
    expect(registry.entities.toSet().difference(catalog.toSet()), isEmpty);
  });

  group('round trip', () {
    for (final entity in catalog) {
      final roundTrip = registry[entity];
      final entityRows = rows.where((r) => r.entity == entity).toList();
      test(entity, () {
        for (final row in entityRows) {
          expect(roundTrip!(row.json), equals(row.json), reason: '$row');
        }
      }, skip: roundTrip == null ? 'no model registered yet' : false);
    }
  });
}
