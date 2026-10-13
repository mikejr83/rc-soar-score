import 'package:drift/drift.dart';

import 'accounts_table.dart';

/// `AccountAlias`: a claimed Local account id and the account it stands for.
///
/// `id` is the Local account id itself, so it has no foreign key to
/// `accounts`: no account row exists for it.
@DataClassName('AccountAliasData')
class AccountAliases extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get claimedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `account_aliases` that hold JSON as text.
const accountAliasesJsonColumns = <String>{};
