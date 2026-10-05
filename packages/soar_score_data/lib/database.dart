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
