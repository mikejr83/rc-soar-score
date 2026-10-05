import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `Account`: the table of accounts, one column per model field.
@DataClassName('AccountData')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text().nullable()();
  BoolColumn get emailVerified => boolean()();
  TextColumn get kind => text().check(kind.isIn(accountKindValues))();
  TextColumn get status => text().check(status.isIn(accountStatusValues))();
  TextColumn get archivedAt => text().nullable()();
  BoolColumn get isSystemAdmin => boolean()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {email},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (email IS NULL OR email = lower(email))',
  ];
}

/// Columns of `accounts` that hold JSON as text.
const accountsJsonColumns = <String>{};
