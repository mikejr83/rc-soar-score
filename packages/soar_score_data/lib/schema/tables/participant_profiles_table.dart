import 'package:drift/drift.dart';

/// `ParticipantProfile`: the table of participant profiles, one column per model field.
@DataClassName('ParticipantProfileData')
class ParticipantProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get club => text().nullable()();
  TextColumn get faiNumber => text().nullable()();
  TextColumn get nationalOrgId => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `participant_profiles` that hold JSON as text.
const participantProfilesJsonColumns = <String>{};
