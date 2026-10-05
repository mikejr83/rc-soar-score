import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'accounts_table.dart';

/// `Installation`: the table of installations, one column per model field.
@DataClassName('InstallationData')
class Installations extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text().references(Accounts, #id)();
  TextColumn get label => text()();
  TextColumn get platform => text().check(platform.isIn(platformValues))();
  TextColumn get createdAt => text()();
  TextColumn get lastSeenAt => text().nullable()();
  TextColumn get lastSyncAt => text().nullable()();
  IntColumn get systemDataSeq => integer()();
  TextColumn get revokedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `installations` that hold JSON as text.
const installationsJsonColumns = <String>{};
