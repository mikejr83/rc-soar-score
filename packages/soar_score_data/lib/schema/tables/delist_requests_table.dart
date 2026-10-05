import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'accounts_table.dart';
import 'publication_identities_table.dart';

/// `DelistRequest`: the table of delist requests, one column per model field.
@DataClassName('DelistRequestData')
class DelistRequests extends Table {
  TextColumn get id => text()();
  TextColumn get publicationId =>
      text().references(PublicationIdentities, #id)();
  TextColumn get requestedBy => text().references(Accounts, #id)();
  TextColumn get trigger => text().check(trigger.isIn(delistTriggerValues))();
  TextColumn get reason => text().nullable()();
  TextColumn get requestedAt => text()();
  TextColumn get state => text().check(state.isIn(delistStateValues))();
  TextColumn get decidedBy => text().nullable().references(Accounts, #id)();
  TextColumn get decidedAt => text().nullable()();
  TextColumn get decisionNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `delist_requests` that hold JSON as text.
const delistRequestsJsonColumns = <String>{};
