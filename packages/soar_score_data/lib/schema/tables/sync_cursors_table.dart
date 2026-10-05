import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'installations_table.dart';

/// `SyncCursor`: the table of sync cursors, one column per model field.
@DataClassName('SyncCursorData')
class SyncCursors extends Table {
  TextColumn get id => text()();
  TextColumn get installationId => text().references(Installations, #id)();
  TextColumn get contestId => text().nullable()();
  TextColumn get ownerAccountId =>
      text().nullable().references(Accounts, #id)();
  IntColumn get lastSyncedSequence => integer()();
  TextColumn get lastSyncedAt => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {installationId, contestId},
    {installationId, ownerAccountId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK ((contest_id IS NULL) <> (owner_account_id IS NULL))',
  ];
}

/// Columns of `sync_cursors` that hold JSON as text.
const syncCursorsJsonColumns = <String>{};
