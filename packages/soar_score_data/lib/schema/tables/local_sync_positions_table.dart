import 'package:drift/drift.dart';

/// An installation's own sync position for one scope.
///
/// Client only. `SyncCursor` stays on the server, which tracks each
/// installation; this is the installation's copy, advanced only after the
/// changes it covers are stored.
@DataClassName('LocalSyncPositionData')
class LocalSyncPositions extends Table {
  /// `Contest`, `Director` or `System`.
  TextColumn get scopeKind =>
      text().check(scopeKind.isIn(const ['Contest', 'Director', 'System']))();

  /// The contest id, the director's account id, or `system` for the one
  /// system-data stream.
  TextColumn get scopeId => text()();

  IntColumn get lastSyncedSequence =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastSyncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {scopeKind, scopeId};
}
