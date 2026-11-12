import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_core/soar_score_core.dart' show SyncScopeKey;
import 'package:soar_score_data/postgres_config.dart';

import 'contests_table.dart';
import 'migrate.dart';
import 'sync/current_attempt_pointer.dart';
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
import 'schema/tables/import_provenance_table.dart';
import 'schema/tables/pilot_import_links_table.dart';
import 'schema/tables/landing_results_table.dart';
import 'schema/tables/landing_tables_table.dart';
import 'schema/tables/local_account_table.dart';
import 'schema/tables/local_sync_positions_table.dart';
import 'schema/tables/model_catalogs_table.dart';
import 'schema/tables/accounts_table.dart';
import 'schema/tables/account_aliases_table.dart';
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
import 'timing/statement_timing_interceptor.dart';

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
    ImportProvenances,
    PilotImportLinks,
    Accounts,
    AccountAliases,
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
    LocalAccount,
  ],
)
class SoarScoreDatabase extends _$SoarScoreDatabase {
  /// Opens the database against [executor], creating the groups of [profile].
  SoarScoreDatabase(QueryExecutor executor, {required this.profile})
    : super(executor);

  final DatabaseProfile profile;

  final _localChanges = StreamController<SyncScopeKey>.broadcast();

  /// The scope of every local write once it has committed.
  ///
  /// The sync scheduler listens here to push soon after a change. A write made
  /// by applying a replicated change is not announced.
  Stream<SyncScopeKey> get localChanges => _localChanges.stream;

  /// Called by the unit of work after a commit.
  void announceLocalChange(SyncScopeKey scope) {
    if (!_localChanges.isClosed) _localChanges.add(scope);
  }

  @override
  Future<void> close() async {
    await _localChanges.close();
    await super.close();
  }

  /// The tables this database creates.
  List<TableInfo<Table, Object?>> get profileTables =>
      tablesFor(profile, allTables);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => createCurrentSchema(m, profileTables),
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless asked; PostgreSQL always checks.
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
    onUpgrade: (m, from, to) async {
      if (from != 1 || to != 2) {
        throw UnsupportedError(
          'Schema upgrade from $from to $to is not supported.',
        );
      }
      await transaction(() async {
        final tableLookup = executor.dialect == SqlDialect.sqlite
            ? "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'pilot_import_links'"
            : "SELECT table_name AS name FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'pilot_import_links'";
        if ((await customSelect(tableLookup).get()).isNotEmpty) {
          if (!await _compatiblePilotImportLinks()) {
            throw StateError(
              'Version 1 database contains an incompatible pilot_import_links '
              'table. No data was changed.',
            );
          }
        } else {
          await m.createTable(pilotImportLinks);
        }
        await _addCurrentAttemptId();
        await _addUploadOpen();
      });
    },
  );

  /// Adds `score_placeholders.current_attempt_id` (unreleased version 2) and
  /// fills it: the attempt behind the current official score, else the
  /// latest accepted attempt of the slot.
  Future<void> _addCurrentAttemptId() async {
    final sqlite = executor.dialect == SqlDialect.sqlite;
    final has = sqlite
        ? await customSelect(
            "SELECT 1 AS x FROM pragma_table_info('score_placeholders') WHERE name = 'current_attempt_id'",
          ).get()
        : await customSelect(
            "SELECT 1 AS x FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'score_placeholders' AND column_name = 'current_attempt_id'",
          ).get();
    if (has.isNotEmpty) return;
    await customStatement(
      'ALTER TABLE score_placeholders ADD COLUMN current_attempt_id TEXT',
    );
    await fillCurrentAttemptIds(this);
  }

  /// Adds `installation_activations.upload_open` (unreleased version 2): false
  /// for every existing activation, so no first upload is open after the
  /// upgrade.
  Future<void> _addUploadOpen() async {
    final sqlite = executor.dialect == SqlDialect.sqlite;
    // Only the server profile has the table.
    final table = sqlite
        ? "SELECT 1 AS x FROM sqlite_master WHERE type = 'table' AND name = 'installation_activations'"
        : "SELECT 1 AS x FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'installation_activations'";
    if ((await customSelect(table).get()).isEmpty) return;
    final has = sqlite
        ? await customSelect(
            "SELECT 1 AS x FROM pragma_table_info('installation_activations') WHERE name = 'upload_open'",
          ).get()
        : await customSelect(
            "SELECT 1 AS x FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'installation_activations' AND column_name = 'upload_open'",
          ).get();
    if (has.isNotEmpty) return;
    await customStatement(
      sqlite
          ? 'ALTER TABLE installation_activations ADD COLUMN upload_open INTEGER NOT NULL DEFAULT 0 CHECK ("upload_open" IN (0, 1))'
          : 'ALTER TABLE installation_activations ADD COLUMN upload_open boolean NOT NULL DEFAULT false',
    );
  }

  /// Recognizes the alpha version of the table without changing its rows.
  Future<bool> _compatiblePilotImportLinks() async {
    const expected = <String, String>{
      'id': 'text',
      'owner_account_id': 'text',
      'source_system': 'text',
      'source_pilot_no': 'integer',
      'participant_profile_id': 'text',
      'source_values': 'text',
      'created_at': 'text',
      'updated_at': 'text',
      'revision': 'integer',
    };
    final sqlite = executor.dialect == SqlDialect.sqlite;
    final columns = await customSelect(
      sqlite ? 'PRAGMA table_info("pilot_import_links")' : "SELECT column_name AS name, data_type AS type, is_nullable, column_default AS dflt_value FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'pilot_import_links'",
    ).get();
    if (columns.length != expected.length) return false;
    for (final row in columns) {
      final name = row.read<String>('name');
      final expectedType = expected[name];
      final actualType = row.read<String>('type').toLowerCase();
      final requiredType = expectedType == 'integer' && !sqlite
          ? 'bigint'
          : expectedType;
      if (requiredType == null || requiredType != actualType) {
        return false;
      }
      if (sqlite
          ? row.read<int>('notnull') != 1
          : row.read<String>('is_nullable') != 'NO') {
        return false;
      }
      if (name == 'revision' &&
          !RegExp(r'\b0\b').hasMatch('${row.data['dflt_value']}')) {
        return false;
      }
    }
    final uniqueSets = <String>[];
    if (sqlite) {
      final primary = columns.where((row) => row.read<int>('pk') > 0).toList();
      if (primary.length != 1 || primary.single.read<String>('name') != 'id') {
        return false;
      }
      final indexes = await customSelect(
        'PRAGMA index_list("pilot_import_links")',
      ).get();
      for (final index in indexes.where(
        (row) => row.read<int>('unique') == 1 && row.read<int>('partial') == 0,
      )) {
        final name = index.read<String>('name');
        final safe = name.replaceAll('"', '""');
        final parts = await customSelect('PRAGMA index_info("$safe")').get();
        uniqueSets.add(parts.map((row) => row.read<String>('name')).join(','));
      }
    } else {
      final constraints = await customSelect(
        "SELECT tc.constraint_name, tc.constraint_type, kcu.column_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.constraint_schema = kcu.constraint_schema AND tc.table_name = kcu.table_name WHERE tc.table_schema = current_schema() AND tc.table_name = 'pilot_import_links' AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE') ORDER BY tc.constraint_name, kcu.ordinal_position",
      ).get();
      final groups = <String, List<String>>{};
      final types = <String, String>{};
      for (final row in constraints) {
        final name = row.read<String>('constraint_name');
        (groups[name] ??= []).add(row.read<String>('column_name'));
        types[name] = row.read<String>('constraint_type');
      }
      if (!groups.entries.any(
        (e) => types[e.key] == 'PRIMARY KEY' && e.value.join(',') == 'id',
      )) {
        return false;
      }
      uniqueSets.addAll(
        groups.entries
            .where((e) => types[e.key] == 'UNIQUE')
            .map((e) => e.value.join(',')),
      );
    }
    return uniqueSets.contains(
      'owner_account_id,source_system,source_pilot_no',
    );
  }
}

/// Opens the local SQLite database at [dbFilePath].
///
/// SQLite runs on a background isolate, so the SQL and row decoding of a
/// large write (an import, a sync pull or push) never stall the UI isolate.
/// Pass `inBackground: false` to run it on the calling isolate.
SoarScoreDatabase createLocalDatabase(
  File dbFilePath, {
  bool inBackground = true,
  QueryInterceptor? interceptor,
}) {
  final native = inBackground
      ? NativeDatabase.createInBackground(dbFilePath, enableMigrations: true)
      : NativeDatabase(dbFilePath, enableMigrations: true);
  final executor = interceptor == null
      ? native
      : native.interceptWith(interceptor);
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

SoarScoreDatabase createInMemoryDatabase() {
  final executor = NativeDatabase.memory();
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

/// Opens the PostgreSQL database for [config].
///
/// With [logStatementDurations] every statement's duration is logged by a
/// [StatementTimingInterceptor] (SQL text and argument count only, never
/// values).
SoarScoreDatabase createPostgresDatabase(
  PostgresConfig config, {
  bool logStatementDurations = false,
}) {
  final pg = config.toPgDatabase();
  return SoarScoreDatabase(
    logStatementDurations ? pg.interceptWith(StatementTimingInterceptor()) : pg,
    profile: DatabaseProfile.server,
  );
}
