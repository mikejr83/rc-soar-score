import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'accounts_table.dart';
import 'installations_table.dart';

/// `InstallationActivation`: the table of installation activations, one column per model field.
@DataClassName('InstallationActivationData')
class InstallationActivations extends Table {
  TextColumn get id => text()();
  TextColumn get contestId => text()();
  TextColumn get installationId => text().references(Installations, #id)();
  TextColumn get activatedBy => text().references(Accounts, #id)();
  TextColumn get kind => text().check(kind.isIn(activationKindValues))();
  TextColumn get activatedAt => text()();
  TextColumn get endedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `installation_activations` that hold JSON as text.
const installationActivationsJsonColumns = <String>{};
