import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'contest_participations_table.dart';
import 'model_catalogs_table.dart';

/// `ContestModelLink`: the table of contest model links, one column per model field.
@DataClassName('ContestModelLinkData')
class ContestModelLinks extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get modelCatalogId => text()
      .references(ModelCatalogs, #id, onDelete: KeyAction.setNull)
      .nullable()();
  TextColumn get modelName => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get modelId => text().nullable()();
  TextColumn get contestSpecificIdentifier => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `contest_model_links` that hold JSON as text.
const contestModelLinksJsonColumns = <String>{};
