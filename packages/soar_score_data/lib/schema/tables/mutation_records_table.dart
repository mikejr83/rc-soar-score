import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `MutationRecord`: the outbox on a client and the accepted log on the server.
///
/// No foreign keys: a record must outlive the entity and contest it names.
/// Exactly one of `contest_id` and `owner_account_id` is set, and a client
/// mutation id is unique within its scope, which makes a retried request
/// idempotent.
@DataClassName('MutationRecordData')
class MutationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get contestId => text().nullable()();
  TextColumn get ownerAccountId => text().nullable()();
  IntColumn get sequence => integer().nullable()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get baseRevision => integer().nullable()();
  TextColumn get clientMutationId => text()();
  TextColumn get actorId => text().nullable()();
  TextColumn get authority => text().check(authority.isIn(authorityValues))();
  TextColumn get sourceInstallationId => text().nullable()();
  TextColumn get sourceDevice => text().nullable()();
  TextColumn get clientTime => text()();
  TextColumn get serverAcceptanceTime => text().nullable()();
  TextColumn get serverRejectionTime => text().nullable()();

  /// A `VersionedPayload` as JSON text.
  TextColumn get payload => text()();
  TextColumn get outcome => text().check(outcome.isIn(mutationOutcomeValues))();
  TextColumn get reasonCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get dependsOnMutationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, clientMutationId},
    {ownerAccountId, clientMutationId},
    {contestId, sequence},
    {ownerAccountId, sequence},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK ((contest_id IS NULL) <> (owner_account_id IS NULL))',
    "CHECK (sequence IS NULL OR outcome = 'Accepted')",
  ];
}
