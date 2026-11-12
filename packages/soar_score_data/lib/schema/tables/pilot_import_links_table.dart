import 'package:drift/drift.dart';

/// Confirmed source pilot associations; independent of provenance history.
@DataClassName('PilotImportLinkData')
class PilotImportLinks extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get sourceSystem => text()();
  IntColumn get sourcePilotNo => integer()();
  TextColumn get participantProfileId => text()();
  TextColumn get sourceValues => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {ownerAccountId, sourceSystem, sourcePilotNo},
  ];
}
