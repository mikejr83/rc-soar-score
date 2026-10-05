import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'accounts_table.dart';
import 'publication_identities_table.dart';

/// `PublicationProjection`: the table of publication projections, one column per model field.
@DataClassName('PublicationProjectionData')
class PublicationProjections extends Table {
  TextColumn get id => text()();
  TextColumn get publicationId =>
      text().references(PublicationIdentities, #id)();
  IntColumn get projectionRevision => integer()();
  IntColumn get contestRevision => integer()();
  IntColumn get configRevision => integer()();
  IntColumn get matrixRevision => integer()();
  TextColumn get disciplineType =>
      text().check(disciplineType.isIn(disciplineTypeValues))();
  IntColumn get disciplineRulesVersion => integer()();
  TextColumn get calculationVersion => text()();
  TextColumn get contestIdentity => text()();
  TextColumn get participants => text().nullable()();
  TextColumn get teams => text().nullable()();
  TextColumn get matrixInfo => text().nullable()();
  TextColumn get scores => text().nullable()();
  TextColumn get standings => text().nullable()();
  TextColumn get calculationMetadata => text().nullable()();
  TextColumn get publishedAt => text()();
  TextColumn get publishedBy => text().nullable().references(Accounts, #id)();
  TextColumn get clientMutationId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {publicationId, projectionRevision},
    {publicationId, clientMutationId},
  ];
}

/// Columns of `publication_projections` that hold JSON as text.
const publicationProjectionsJsonColumns = <String>{
  'contest_identity',
  'participants',
  'teams',
  'matrix_info',
  'scores',
  'standings',
  'calculation_metadata',
};
