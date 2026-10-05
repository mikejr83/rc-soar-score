import 'package:drift/drift.dart';

import 'accounts_table.dart';

/// `ParticipantDirectoryEntry`: the table of participant directory entries, one column per model field.
@DataClassName('ParticipantDirectoryEntryData')
class ParticipantDirectoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get club => text().nullable()();
  TextColumn get faiNumber => text().nullable()();
  TextColumn get nationalOrgId => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  BoolColumn get isListed => boolean()();
  BoolColumn get emailVisibleToDirectors => boolean()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId},
  ];
}

/// Columns of `participant_directory_entries` that hold JSON as text.
const participantDirectoryEntriesJsonColumns = <String>{};
