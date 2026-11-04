import 'package:drift/drift.dart';

/// `ImportProvenance`: the table of import stamps, one column per model field.
///
/// The table is director data. `contest_id` and `stamped_entity_id` are plain
/// text, not references: a stamp must outlive the profile it describes, and a
/// contest delete removes its stamps through the repository so the removal
/// syncs.
@DataClassName('ImportProvenanceData')
class ImportProvenances extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get contestId => text().nullable()();
  TextColumn get stampedEntityType => text()();
  TextColumn get stampedEntityId => text()();
  TextColumn get sourceSystem => text()();
  TextColumn get sourceKeys => text()();
  TextColumn get sourceValues => text().nullable()();
  TextColumn get fileFingerprint => text()();
  TextColumn get dedupeKey => text().nullable()();
  TextColumn get importOperationId => text()();
  TextColumn get toolVersion => text()();
  TextColumn get importedAt => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The singular name the data-model docs use.
  @override
  String get tableName => 'import_provenance';

  @override
  Set<Column> get primaryKey => {id};

  /// One contest stamp per owner and competition. Rows without a dedupe key
  /// (participation and profile stamps) are never equal, so they never clash.
  @override
  List<Set<Column>> get uniqueKeys => [
    {ownerAccountId, dedupeKey},
  ];
}

/// Columns of `import_provenance` that hold JSON as text.
const importProvenancesJsonColumns = <String>{'source_keys', 'source_values'};
