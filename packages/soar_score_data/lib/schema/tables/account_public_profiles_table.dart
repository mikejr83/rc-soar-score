import 'package:drift/drift.dart';

import 'accounts_table.dart';

/// `AccountPublicProfile`: the table of account public profiles, one column per model field.
@DataClassName('AccountPublicProfileData')
class AccountPublicProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get displayName => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId},
  ];
}

/// Columns of `account_public_profiles` that hold JSON as text.
const accountPublicProfilesJsonColumns = <String>{};
