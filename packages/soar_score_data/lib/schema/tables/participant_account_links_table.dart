import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'accounts_table.dart';

/// `ParticipantAccountLink`: the table of participant account links, one column per model field.
@DataClassName('ParticipantAccountLinkData')
class ParticipantAccountLinks extends Table {
  TextColumn get id => text()();
  TextColumn get participantProfileId => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get status =>
      text().check(status.isIn(participantLinkStatusValues))();
  TextColumn get origin =>
      text().check(origin.isIn(participantLinkOriginValues))();
  TextColumn get createdAt => text()();
  TextColumn get confirmedAt => text().nullable()();
  TextColumn get endedAt => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {participantProfileId, accountId},
  ];
}

/// Columns of `participant_account_links` that hold JSON as text.
const participantAccountLinksJsonColumns = <String>{};
