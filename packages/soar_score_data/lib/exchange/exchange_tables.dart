/// How the contest export treats each table of a native database.
enum ExchangeClass {
  /// The contest's own rows, found by contest id.
  contest,

  /// The director's rows the contest points at (only those it references).
  director,

  /// Director-scoped data that is not part of a contest export.
  directorPrivate,

  /// Calculated rows: kept in the file's diagnostics, recomputed on import.
  derived,

  /// Discipline data every installation ships; import checks it is present.
  system,

  /// State of one installation, never exported.
  installationState,

  /// Rows only the service can issue, left out until the service is involved.
  serviceIssued,

  /// Tables the service keeps; an installation does not have them.
  serviceOnly,
}

/// One exported table: its SQL name, its entity type in the sync stores, and
/// the column that ties a row to the contest (`id` for the contest itself).
class ExchangeTable {
  const ExchangeTable(this.table, this.entityType, this.contestColumn);

  final String table;
  final String entityType;
  final String contestColumn;
}

/// The contest's own tables in dependency order, so every row follows the
/// rows it refers to.
const contestExchangeTables = <ExchangeTable>[
  ExchangeTable('contests', 'Contest', 'id'),
  ExchangeTable(
    'contest_configuration_revisions',
    'ContestConfigurationRevision',
    'contest_id',
  ),
  ExchangeTable('contest_participations', 'ContestParticipation', 'contest_id'),
  ExchangeTable('teams', 'Team', 'contest_id'),
  ExchangeTable('team_memberships', 'TeamMembership', 'contest_id'),
  ExchangeTable('contest_model_links', 'ContestModelLink', 'contest_id'),
  // The contest's and its participations' import stamps. Profile stamps carry
  // no contest and stay with the director's data.
  ExchangeTable('import_provenance', 'ImportProvenance', 'contest_id'),
  ExchangeTable('matrix_revisions', 'MatrixRevision', 'contest_id'),
  ExchangeTable('rounds', 'Round', 'contest_id'),
  ExchangeTable('round_groups', 'RoundGroup', 'contest_id'),
  ExchangeTable('re_flights', 'ReFlight', 'contest_id'),
  ExchangeTable('matrix_assignments', 'MatrixAssignment', 'contest_id'),
  ExchangeTable('re_flight_participants', 'ReFlightParticipant', 'contest_id'),
  ExchangeTable('score_placeholders', 'ScorePlaceholder', 'contest_id'),
  ExchangeTable('score_attempts', 'ScoreAttempt', 'contest_id'),
  ExchangeTable('official_scores', 'OfficialScore', 'contest_id'),
  ExchangeTable('review_requests', 'ReviewRequest', 'contest_id'),
  ExchangeTable('mutation_records', 'MutationRecord', 'contest_id'),
  ExchangeTable('conflict_records', 'ConflictRecord', 'contest_id'),
  ExchangeTable('audit_events', 'AuditEvent', 'contest_id'),
  ExchangeTable('tombstones', 'Tombstone', 'contest_id'),
];

/// The director tables in dependency order. Only the rows the contest points
/// at are exported.
const directorExchangeTables = <ExchangeTable>[
  ExchangeTable('landing_tables', 'LandingTable', 'id'),
  ExchangeTable('landing_results', 'LandingResult', 'landing_table_id'),
  ExchangeTable(
    'contest_configuration_presets',
    'ContestConfigurationPreset',
    'id',
  ),
  ExchangeTable('participant_profiles', 'ParticipantProfile', 'id'),
  ExchangeTable('roles', 'Role', 'id'),
  ExchangeTable('model_catalogs', 'ModelCatalog', 'id'),
];

/// The calculated tables, by contest column. Kept as seen in the diagnostics.
const derivedExchangeTables = <ExchangeTable>[
  ExchangeTable('flight_results', 'FlightResult', 'contest_id'),
  ExchangeTable(
    'participation_standings',
    'ParticipationStanding',
    'contest_id',
  ),
  ExchangeTable('team_standings', 'TeamStanding', 'contest_id'),
];

/// The class of every table, by SQL table name.
///
/// A test requires every table of the native profile to be listed here, so a
/// new table cannot reach an export (or be left out of it) unnoticed.
final exchangeClassByTable = <String, ExchangeClass>{
  for (final t in contestExchangeTables) t.table: ExchangeClass.contest,
  for (final t in directorExchangeTables) t.table: ExchangeClass.director,
  for (final t in derivedExchangeTables) t.table: ExchangeClass.derived,
  'discipline_profiles': ExchangeClass.system,
  'discipline_config_fields': ExchangeClass.system,
  'discipline_score_fields': ExchangeClass.system,
  'discipline_validations': ExchangeClass.system,
  'discipline_formulas': ExchangeClass.system,
  'discipline_rules': ExchangeClass.system,
  'pilot_import_links': ExchangeClass.directorPrivate,
  'local_sync_positions': ExchangeClass.installationState,
  'local_account': ExchangeClass.installationState,
  'invitations': ExchangeClass.serviceIssued,
  'accounts': ExchangeClass.serviceOnly,
  'account_aliases': ExchangeClass.serviceOnly,
  'account_identities': ExchangeClass.serviceOnly,
  'account_public_profiles': ExchangeClass.serviceOnly,
  'participant_account_links': ExchangeClass.serviceOnly,
  'participant_directory_entries': ExchangeClass.serviceOnly,
  'installations': ExchangeClass.serviceOnly,
  'installation_activations': ExchangeClass.serviceOnly,
  'sync_cursors': ExchangeClass.serviceOnly,
  'publication_identities': ExchangeClass.serviceOnly,
  'publication_projections': ExchangeClass.serviceOnly,
  'publication_participants': ExchangeClass.serviceOnly,
  'delist_requests': ExchangeClass.serviceOnly,
  'request_throttles': ExchangeClass.serviceOnly,
};
