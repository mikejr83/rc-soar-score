import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'account_public_profiles_table.dart';

/// `PublicationIdentity`: the table of publication identities, one column per model field.
@DataClassName('PublicationIdentityData')
class PublicationIdentities extends Table {
  TextColumn get id => text()();
  TextColumn get contestId => text().nullable().references(
    Contests,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get ownerPublicProfileId =>
      text().nullable().references(AccountPublicProfiles, #id)();
  TextColumn get claimStatus =>
      text().check(claimStatus.isIn(claimStatusValues))();
  TextColumn get verificationEmail => text().nullable()();
  TextColumn get visibility =>
      text().check(visibility.isIn(publicationVisibilityValues))();
  TextColumn get publishedAt => text().nullable()();
  TextColumn get currentProjectionId => text().nullable()();
  IntColumn get resultsHiddenThroughRound => integer().nullable()();
  TextColumn get resultsHiddenAt => text().nullable()();
  TextColumn get contestName => text().nullable()();
  TextColumn get contestStartsAt => text().nullable()();
  TextColumn get contestEndsAt => text().nullable()();
  TextColumn get venue => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((results_hidden_at IS NULL) = (results_hidden_through_round IS NULL))',
  ];
}

/// Columns of `publication_identities` that hold JSON as text.
const publicationIdentitiesJsonColumns = <String>{};
