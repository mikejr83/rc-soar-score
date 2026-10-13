import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `ConflictRecord`: a competing mutation that lost, or needs a decision.
@DataClassName('ConflictRecordData')
class ConflictRecords extends Table {
  TextColumn get id => text()();
  TextColumn get contestId => text().nullable()();
  TextColumn get ownerAccountId => text().nullable()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get acceptedMutationId => text().nullable()();
  TextColumn get competingMutationId => text()();
  TextColumn get reasonCode => text()();
  TextColumn get reason => text().nullable()();
  BoolColumn get requiresAction =>
      boolean().withDefault(const Constant(true))();
  TextColumn get resolution =>
      text().check(resolution.isIn(conflictResolutionValues))();
  TextColumn get resolutionChoice => text().nullable().check(
    resolutionChoice.isIn(conflictResolutionChoiceValues),
  )();
  TextColumn get createdAt => text()();
  TextColumn get resolvedAt => text().nullable()();
  TextColumn get resolvedBy => text().nullable()();

  /// JSON: the entity state the service applied, and the colliding mutation's.
  TextColumn get acceptedPayload => text().nullable()();
  TextColumn get competingPayload => text().nullable()();
  IntColumn get entityRevision => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((contest_id IS NULL) <> (owner_account_id IS NULL))',
  ];
}

/// Columns of `conflict_records` that hold JSON as text.
const conflictRecordsJsonColumns = <String>{
  'accepted_payload',
  'competing_payload',
};
