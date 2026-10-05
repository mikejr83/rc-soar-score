import '../../enums/landing_input_unit.dart';
import '../id.dart';
import 'landing_result.dart';
import 'landing_table.dart';
import 'landing_table_with_results.dart';

/// The landing tables the system ships, with fixed ids.
///
/// The ids match `plan/data-model/examples/disciplines/f5j.md`, so a profile
/// can name its default table by id. A shipped table is never edited: a
/// change is a new table with new ids.
abstract final class SystemLandingTables {
  /// The F5J default: the scorer selects the points directly.
  static final f5jStandardId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02');

  /// The common alternative: the scorer selects a distance in meters.
  static final f5jDistanceId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00');

  /// Every table the system ships, for the seeder.
  static List<LandingTableWithResults> get all => [f5jStandard, f5jDistance];

  static final f5jStandard = _table(
    id: f5jStandardId,
    name: 'F5J Standard Landing Table',
    inputUnit: LandingInputUnit.points,
    idPrefix: '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d',
    entries: [
      for (var points = 50; points >= 0; points -= 5)
        (key: 'points_$points', label: '$points pts', points: points),
    ],
  );

  static final f5jDistance = _table(
    id: f5jDistanceId,
    name: 'F5J Landing Distance Table',
    inputUnit: LandingInputUnit.meters,
    idPrefix: '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e',
    entries: [
      for (var meters = 1; meters <= 10; meters++)
        (
          key: 'within_${meters}m',
          label: '${meters}m',
          points: 55 - 5 * meters,
        ),
      (key: 'over_10m', label: 'Over 10m', points: 0),
    ],
  );

  /// A table whose entry ids are [idPrefix] plus a two-digit hex counter.
  static LandingTableWithResults _table({
    required Id id,
    required String name,
    required LandingInputUnit inputUnit,
    required String idPrefix,
    required List<({String key, String label, int points})> entries,
  }) => LandingTableWithResults(
    table: LandingTable(
      id: id,
      name: name,
      inputUnit: inputUnit,
      createdAt: DateTime.utc(2026, 9, 15),
    ),
    results: [
      for (var i = 0; i < entries.length; i++)
        LandingResult(
          id: Id.parse('$idPrefix${(i + 1).toRadixString(16).padLeft(2, '0')}'),
          landingTableId: id,
          entryKey: entries[i].key,
          displayValue: entries[i].label,
          pointValue: entries[i].points,
          ordinalPosition: i + 1,
        ),
    ],
  );
}
