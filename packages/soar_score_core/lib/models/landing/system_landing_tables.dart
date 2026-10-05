import '../../enums/landing_input_unit.dart';
import '../id.dart';
import 'landing_result.dart';
import 'landing_table.dart';
import 'landing_table_with_results.dart';

/// The landing tables the system ships, with fixed ids.
///
/// The ids match the documents in `plan/data-model/examples/disciplines/`,
/// so a profile can name its default table by id. A shipped table is never
/// edited: a change is a new table with new ids.
abstract final class SystemLandingTables {
  /// The F5J default: the scorer selects the points directly.
  static final f5jStandardId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02');

  /// The common alternative: the scorer selects a distance in meters.
  static final f5jDistanceId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00');

  /// The F3J default: the scorer selects the points directly.
  static final f3jStandardId = Id.parse('019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02');

  /// The official F3J table: the scorer selects a distance in meters.
  static final f3jDistanceId = Id.parse('019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00');

  /// The ALES default: the scorer selects the points directly.
  static final alesStandardId = Id.parse(
    '019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02',
  );

  /// The Thermal Duration default, a 100 inch landing tape: the scorer
  /// selects the points directly, one point per inch.
  static final thermalStandardId = Id.parse(
    '019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02',
  );

  /// Every table the system ships, for the seeder.
  static List<LandingTableWithResults> get all => [
    f5jStandard,
    f5jDistance,
    f3jStandard,
    f3jDistance,
    alesStandard,
    thermalStandard,
  ];

  static final f5jStandard = _table(
    id: f5jStandardId,
    name: 'F5J Standard Landing Table',
    inputUnit: LandingInputUnit.points,
    idPrefix: '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d',
    entries: _pointEntries(50, step: 5),
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

  static final f3jStandard = _table(
    id: f3jStandardId,
    name: 'F3J Standard Landing Table',
    inputUnit: LandingInputUnit.points,
    idPrefix: '019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b',
    entries: [
      for (final (_, points) in _f3jDistances)
        (key: 'points_$points', label: '$points pts', points: points),
      (key: 'points_0', label: '0 pts', points: 0),
    ],
  );

  static final f3jDistance = _table(
    id: f3jDistanceId,
    name: 'F3J Landing Distance Table',
    inputUnit: LandingInputUnit.meters,
    idPrefix: '019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d',
    entries: [
      for (final (meters, points) in _f3jDistances)
        (
          key: 'within_${meters.replaceAll('.', '_')}m',
          label: '${meters}m',
          points: points,
        ),
      (key: 'over_15m', label: 'Over 15m', points: 0),
    ],
  );

  /// The official F3J landing table: the distance from the spot, up to which
  /// the points are awarded. Farther than 15 m earns 0.
  static const _f3jDistances = <(String, int)>[
    ('0.2', 100),
    ('0.4', 99),
    ('0.6', 98),
    ('0.8', 97),
    ('1', 96),
    ('1.2', 95),
    ('1.4', 94),
    ('1.6', 93),
    ('1.8', 92),
    ('2', 91),
    ('3', 90),
    ('4', 85),
    ('5', 80),
    ('6', 75),
    ('7', 70),
    ('8', 65),
    ('9', 60),
    ('10', 55),
    ('11', 50),
    ('12', 45),
    ('13', 40),
    ('14', 35),
    ('15', 30),
  ];

  static final alesStandard = _table(
    id: alesStandardId,
    name: 'ALES Standard Landing Table',
    inputUnit: LandingInputUnit.points,
    idPrefix: '019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e',
    entries: _pointEntries(50, step: 5),
  );

  static final thermalStandard = _table(
    id: thermalStandardId,
    name: 'Thermal Standard Landing Table',
    inputUnit: LandingInputUnit.points,
    idPrefix: '019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d',
    entries: _pointEntries(100, step: 1),
  );

  /// Entries that select the points awarded, from [top] down to 0.
  static List<({String key, String label, int points})> _pointEntries(
    int top, {
    required int step,
  }) => [
    for (var points = top; points >= 0; points -= step)
      (key: 'points_$points', label: '$points pts', points: points),
  ];

  /// A table whose entry ids are [idPrefix] plus a two-digit hex counter that
  /// starts at [firstEntry].
  static LandingTableWithResults _table({
    required Id id,
    required String name,
    required LandingInputUnit inputUnit,
    required String idPrefix,
    required List<({String key, String label, int points})> entries,
    int firstEntry = 1,
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
          id: Id.parse(
            '$idPrefix${(i + firstEntry).toRadixString(16).padLeft(2, '0')}',
          ),
          landingTableId: id,
          entryKey: entries[i].key,
          displayValue: entries[i].label,
          pointValue: entries[i].points,
          ordinalPosition: i + 1,
        ),
    ],
  );
}
