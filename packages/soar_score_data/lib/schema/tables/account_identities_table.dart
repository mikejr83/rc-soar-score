import 'package:drift/drift.dart';

import 'accounts_table.dart';

/// `AccountIdentity`: the table of account identities, one column per model field.
@DataClassName('AccountIdentityData')
class AccountIdentities extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get issuer => text()();
  TextColumn get subject => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {issuer, subject},
  ];
}

/// Columns of `account_identities` that hold JSON as text.
const accountIdentitiesJsonColumns = <String>{};
