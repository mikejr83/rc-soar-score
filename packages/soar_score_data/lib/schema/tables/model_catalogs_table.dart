import 'package:drift/drift.dart';

/// `ModelCatalog`: the table of model catalogs, one column per model field.
@DataClassName('ModelCatalogData')
class ModelCatalogs extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get name => text()();
  TextColumn get manufacturer => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `model_catalogs` that hold JSON as text.
const modelCatalogsJsonColumns = <String>{};
