import 'package:drift/drift.dart';

/// Contest entity table.
///
/// One column per field of `soar_score_core`'s `Contest`, so a saved contest
/// reads back unchanged. Enumerations are stored as the text in the entity
/// document and timestamps as UTC ISO-8601 text. The other entities' tables,
/// revision bumping and the sync outbox belong to ticket 036.
///
/// The generated row class is named `ContestData` (via [DataClassName]) to
/// avoid clashing with `soar_score_core`'s domain `Contest` class.
@DataClassName('ContestData')
class Contests extends Table {
  /// Stable opaque UUIDv7 identifier.
  TextColumn get id => text()();

  /// Contest display name.
  TextColumn get name => text()();

  /// Start (UTC, ISO-8601).
  TextColumn get startDateTime => text()();

  /// End (UTC, ISO-8601).
  TextColumn get endDateTime => text()();

  /// IANA timezone name.
  TextColumn get timezone => text()();

  TextColumn get host => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();

  /// Owning account; null for anonymous or local contests.
  TextColumn get ownerAccountId => text().nullable()();

  /// `Created`, `Configuring`, `Ready`, `Running` or `Completed`.
  TextColumn get lifecycleState => text()();

  /// `Closed` or `Open`.
  TextColumn get scoringAccess => text()();

  /// `Unlocked` or `Locked`.
  TextColumn get adminLock => text()();

  IntColumn get resultsHiddenThroughRound => integer().nullable()();
  TextColumn get resultsHiddenAt => text().nullable()();

  BoolColumn get localArchive => boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
