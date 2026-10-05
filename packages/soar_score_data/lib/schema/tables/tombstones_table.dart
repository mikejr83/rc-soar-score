import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `Tombstone`: the record that an entity was deleted, kept until every
/// installation has acknowledged it.
@DataClassName('TombstoneData')
class Tombstones extends Table {
  TextColumn get id => text()();
  TextColumn get contestId => text().nullable()();
  TextColumn get ownerAccountId => text().nullable()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get status => text().check(status.isIn(tombstoneStatusValues))();
  TextColumn get deletedAt => text()();
  TextColumn get acknowledgedAt => text().nullable()();
  TextColumn get purgeAfter => text().nullable()();
  TextColumn get deletionReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {entityType, entityId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK ((contest_id IS NULL) <> (owner_account_id IS NULL))',
  ];
}
