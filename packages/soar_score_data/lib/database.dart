import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/postgres_config.dart';

import 'contests_table.dart';
import 'migrate.dart';
import 'schema/database_profile.dart';
import 'schema/enum_values.dart';
import 'schema/tables/audit_events_table.dart';
import 'schema/tables/conflict_records_table.dart';
import 'schema/tables/contest_configuration_presets_table.dart';
import 'schema/tables/contest_configuration_revisions_table.dart';
import 'schema/tables/contest_model_links_table.dart';
import 'schema/tables/contest_participations_table.dart';
import 'schema/tables/discipline_config_fields_table.dart';
import 'schema/tables/discipline_formulas_table.dart';
import 'schema/tables/discipline_profiles_table.dart';
import 'schema/tables/discipline_rules_table.dart';
import 'schema/tables/discipline_score_fields_table.dart';
import 'schema/tables/discipline_validations_table.dart';
import 'schema/tables/landing_results_table.dart';
import 'schema/tables/landing_tables_table.dart';
import 'schema/tables/local_sync_positions_table.dart';
import 'schema/tables/model_catalogs_table.dart';
import 'schema/tables/accounts_table.dart';
import 'schema/tables/account_identities_table.dart';
import 'schema/tables/account_public_profiles_table.dart';
import 'schema/tables/participant_account_links_table.dart';
import 'schema/tables/participant_directory_entries_table.dart';
import 'schema/tables/installations_table.dart';
import 'schema/tables/installation_activations_table.dart';
import 'schema/tables/sync_cursors_table.dart';
import 'schema/tables/publication_identities_table.dart';
import 'schema/tables/publication_projections_table.dart';
import 'schema/tables/publication_participants_table.dart';
import 'schema/tables/delist_requests_table.dart';
import 'schema/tables/invitations_table.dart';
import 'schema/tables/matrix_revisions_table.dart';
import 'schema/tables/rounds_table.dart';
import 'schema/tables/round_groups_table.dart';
import 'schema/tables/re_flights_table.dart';
import 'schema/tables/matrix_assignments_table.dart';
import 'schema/tables/re_flight_participants_table.dart';
import 'schema/tables/score_placeholders_table.dart';
import 'schema/tables/score_attempts_table.dart';
import 'schema/tables/official_scores_table.dart';
import 'schema/tables/review_requests_table.dart';
import 'schema/tables/flight_results_table.dart';
import 'schema/tables/participation_standings_table.dart';
import 'schema/tables/team_standings_table.dart';
import 'schema/tables/mutation_records_table.dart';
import 'schema/tables/participant_profiles_table.dart';
import 'schema/tables/roles_table.dart';
import 'schema/tables/team_memberships_table.dart';
import 'schema/tables/teams_table.dart';
import 'schema/tables/tombstones_table.dart';
import 'schema/table_groups.dart';

part 'database.g.dart';

/// Contests database.
///
/// Opens a file-backed or in-memory SQLite database via `package:drift`'s
/// native `dart:ffi` executor and runs the versioned schema migrations. The
/// [profile] decides which table groups are created.
@DriftDatabase(
  tables: [
    Contests,
    LandingTables,
    LandingResults,
    DisciplineProfiles,
    DisciplineConfigFields,
    DisciplineScoreFields,
    DisciplineValidations,
    DisciplineFormulas,
    DisciplineRules,
    ContestConfigurationPresets,
    ContestConfigurationRevisions,
    ParticipantProfiles,
    Roles,
    ContestParticipations,
    Teams,
    TeamMemberships,
    ModelCatalogs,
    ContestModelLinks,
    Accounts,
    AccountIdentities,
    AccountPublicProfiles,
    ParticipantAccountLinks,
    ParticipantDirectoryEntries,
    Installations,
    InstallationActivations,
    SyncCursors,
    PublicationIdentities,
    PublicationProjections,
    PublicationParticipants,
    DelistRequests,
    Invitations,
    MatrixRevisions,
    Rounds,
    RoundGroups,
    ReFlights,
    MatrixAssignments,
    ReFlightParticipants,
    ScorePlaceholders,
    ScoreAttempts,
    OfficialScores,
    ReviewRequests,
    FlightResults,
    ParticipationStandings,
    TeamStandings,
    MutationRecords,
    ConflictRecords,
    Tombstones,
    AuditEvents,
    LocalSyncPositions,
  ],
)
class SoarScoreDatabase extends _$SoarScoreDatabase {
  /// Opens the database against [executor], creating the groups of [profile].
  SoarScoreDatabase(QueryExecutor executor, {required this.profile})
    : super(executor);

  final DatabaseProfile profile;

  /// The tables this database creates.
  List<TableInfo<Table, Object?>> get profileTables =>
      tablesFor(profile, allTables);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => migrateToVersion1(m, profileTables),
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless asked; PostgreSQL always checks.
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
    onUpgrade: (m, from, to) {
      throw UnsupportedError(
        'Schema upgrade from $from to $to is not implemented yet: '
        'only schema version 1 exists (see migrate.dart).',
      );
    },
  );
}

SoarScoreDatabase createLocalDatabase(File dbFilePath) {
  final executor = NativeDatabase(dbFilePath, enableMigrations: true);
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

SoarScoreDatabase createInMemoryDatabase() {
  final executor = NativeDatabase.memory();
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

SoarScoreDatabase createPostgresDatabase(PostgresConfig config) {
  return SoarScoreDatabase(
    config.toPgDatabase(),
    profile: DatabaseProfile.server,
  );
}
