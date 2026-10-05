import 'package:drift/drift.dart';

/// An installation's own sync position for one scope.
///
/// Client only. `SyncCursor` stays on the server, which tracks each
/// installation; this is the installation's copy, advanced only after the
/// changes it covers are stored.
@DataClassName('LocalSyncPositionData')
class LocalSyncPositions extends Table {
  /// `Contest` or `Director`.
  TextColumn get scopeKind =>
      text().check(scopeKind.isIn(const ['Contest', 'Director']))();

  /// The contest id or the director's account id.
  TextColumn get scopeId => text()();

  IntColumn get lastSyncedSequence =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastSyncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {scopeKind, scopeId};
}
