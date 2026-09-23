import 'package:drift/drift.dart';

/// Contest entity table (minimal scaffold schema).
///
/// Only the fields carried by `soar_score_core`'s example `Contest` model are
/// persisted here. Revisioned configuration, matrix, participation, scoring
/// and audit columns are added by later tickets; sync-related fields (pending
/// mutation logs, tombstones, `contest_mutation_seq`) are deferred. Dates are
/// stored as UTC text.
///
/// The generated row class is named `ContestData` (via [DataClassName]) to
/// avoid clashing with `soar_score_core`'s domain `Contest` class.
///
/// Per the decision recorded in ticket 016, this table definition is
/// maintained independently from `soar_score_data_sqlite`'s (column names and
/// semantics are intentionally mirrored so the two can be unified later if
/// needed).
@DataClassName('ContestData')
class Contests extends Table {
  /// Stable opaque UUIDv7 identifier.
  TextColumn get id => text()();

  /// Contest display name.
  TextColumn get name => text()();

  /// Contest start time (UTC, ISO-8601).
  TextColumn get startedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
