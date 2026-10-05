import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `AuditEvent`: the immutable audit trail. Director-only detail, so it is
/// private data and never part of a publication.
@DataClassName('AuditEventData')
class AuditEvents extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get contestId => text().nullable()();
  TextColumn get ownerAccountId => text().nullable()();
  TextColumn get publicationId => text().nullable()();
  TextColumn get action => text().check(action.isIn(auditActionValues))();
  TextColumn get actorId => text().nullable()();
  TextColumn get authority => text().check(authority.isIn(authorityValues))();
  TextColumn get installationId => text().nullable()();
  TextColumn get device => text().nullable()();
  IntColumn get baseRevision => integer().nullable()();
  IntColumn get resultingRevision => integer().nullable()();
  TextColumn get serverTimestamp => text()();
  TextColumn get clientTimestamp => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get outcome => text().check(outcome.isIn(auditOutcomeValues))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((CASE WHEN contest_id IS NULL THEN 0 ELSE 1 END) + '
        '(CASE WHEN owner_account_id IS NULL THEN 0 ELSE 1 END) + '
        '(CASE WHEN publication_id IS NULL THEN 0 ELSE 1 END) <= 1)',
  ];
}
