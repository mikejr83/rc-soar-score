/// The columns that can hold an account id, as table to columns, and so the
/// ones a claim of the Local account re-points.
///
/// Only tables an installation has. A new column that names an account must be
/// listed here or in [accountColumnsNotReassigned]; a test fails otherwise.
const localAccountReferences = <String, List<String>>{
  'contests': ['owner_account_id'],
  'landing_tables': ['owner_account_id'],
  'contest_configuration_presets': ['owner_account_id'],
  'contest_configuration_revisions': ['created_by'],
  'participant_profiles': ['owner_account_id'],
  'roles': ['owner_account_id'],
  'model_catalogs': ['owner_account_id'],
  'import_provenance': ['owner_account_id'],
  'pilot_import_links': ['owner_account_id'],
  'matrix_revisions': ['created_by', 'finalized_by'],
  'matrix_assignments': ['actor_id'],
  're_flights': [
    'created_by',
    'group_finalized_by',
    'finalized_by',
    'cancelled_by',
  ],
  'round_groups': ['locked_by'],
  'score_placeholders': ['locked_by'],
  'score_attempts': ['actor_id'],
  'official_scores': ['set_by'],
  'review_requests': ['decision_actor_id'],
  'invitations': ['issued_by', 'redeemed_by_account_id'],
  'mutation_records': ['owner_account_id', 'actor_id'],
  'conflict_records': ['owner_account_id', 'resolved_by'],
  'audit_events': ['owner_account_id', 'actor_id'],
  'tombstones': ['owner_account_id'],
};

/// Columns that hold JSON text, in which an account id can sit inside a
/// stored mutation or conflict, as table to columns.
const localAccountJsonReferences = <String, List<String>>{
  'mutation_records': ['payload'],
  'conflict_records': ['accepted_payload', 'competing_payload'],
};

/// Columns that look like account references but are left alone, with the
/// reason.
const accountColumnsNotReassigned = <String, String>{
  'discipline_profiles.created_by': 'system data, authored by the system',
  'discipline_profiles.updated_by': 'system data, authored by the system',
  'local_account.account_id': 'the Local account id itself, kept as the alias',
  'local_account.linked_account_id': 'the target of the re-pointing, set by it',
};
