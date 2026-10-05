import 'package:drift/drift.dart';

import 'account_public_profiles_table.dart';
import 'publication_identities_table.dart';

/// `PublicationParticipant`: the table of publication participants, one column per model field.
@DataClassName('PublicationParticipantData')
class PublicationParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get publicationId =>
      text().references(PublicationIdentities, #id)();
  TextColumn get pilotKey => text()();
  TextColumn get sourceParticipationId => text().nullable()();
  TextColumn get details => text().nullable()();
  TextColumn get publicProfileId =>
      text().nullable().references(AccountPublicProfiles, #id)();
  TextColumn get redactedAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {publicationId, pilotKey},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (redacted_at IS NULL OR (details IS NULL AND public_profile_id IS NULL))',
  ];
}

/// Columns of `publication_participants` that hold JSON as text.
const publicationParticipantsJsonColumns = <String>{'details'};
