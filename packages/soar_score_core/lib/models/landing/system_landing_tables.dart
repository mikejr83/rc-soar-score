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
  static final f5jStandardId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02');

  /// Every table the system ships, for the seeder.
  static List<LandingTableWithResults> get all => [f5jStandard];

  static final f5jStandard = _f5jStandard();

  static LandingTableWithResults _f5jStandard() {
    LandingResult entry(
      String id,
      String key,
      String label,
      int points,
      int position,
    ) => LandingResult(
      id: Id.parse(id),
      landingTableId: f5jStandardId,
      entryKey: key,
      displayValue: label,
      pointValue: points,
      ordinalPosition: position,
    );

    return LandingTableWithResults(
      table: LandingTable(
        id: f5jStandardId,
        name: 'F5J Standard Landing Table',
        inputUnit: LandingInputUnit.meters,
        createdAt: DateTime.utc(2026, 9, 15),
      ),
      results: [
        entry(
          '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b03',
          'within_10m',
          'Within 10 m',
          20,
          1,
        ),
        entry(
          '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b04',
          'within_25m',
          'Within 25 m',
          15,
          2,
        ),
        entry(
          '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b05',
          'within_50m',
          'Within 50 m',
          10,
          3,
        ),
        entry(
          '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b06',
          'within_75m',
          'Within 75 m',
          5,
          4,
        ),
        entry('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b07', 'none', 'No bonus', 0, 5),
      ],
    );
  }
}
