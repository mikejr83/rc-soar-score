/// The columns that can hold the id of a guest account, as table to columns,
/// and so the ones a claim of a pilot's guest entries re-points to the
/// pilot's registered account (#545).
///
/// A guest acts only through an invitation: it opens the link (the invitation
/// records it), submits scores (an attempt and its mutation record name it as
/// actor) and leaves audit events. A new column that a guest can write must be
/// listed here, or in [accountColumnsGuestsNeverHold]; a test fails otherwise.
///
/// `mutation_records.payload` keeps the guest id in the stored change: it is
/// the record of what was sent and received, so it is left as written.
const guestAccountReferences = <String, List<String>>{
  'score_attempts': ['actor_id'],
  'invitations': ['redeemed_by_account_id'],
  'audit_events': ['actor_id'],
  'mutation_records': ['actor_id'],
};

/// Columns that look like account references but never hold a guest account,
/// with the reason. A guest has no access to anything a director, an
/// administrator or the system writes.
const accountColumnsGuestsNeverHold = <String, String>{
  'contests.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'landing_tables.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'discipline_profiles.created_by': 'system data, authored by the system',
  'discipline_profiles.updated_by': 'system data, authored by the system',
  'contest_configuration_presets.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'contest_configuration_revisions.created_by':
      'written by a director, never by a guest',
  'participant_profiles.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'roles.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'model_catalogs.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'import_provenance.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'pilot_import_links.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'account_aliases.account_id':
      'the record of a signed-in account, never a guest',
  'account_identities.account_id':
      'the record of a signed-in account, never a guest',
  'account_public_profiles.account_id':
      'the record of a signed-in account, never a guest',
  'participant_account_links.account_id':
      'the record of a signed-in account, never a guest',
  'participant_directory_entries.account_id':
      'the record of a signed-in account, never a guest',
  'installations.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'installation_activations.activated_by':
      'an administrator or director action, never a guest',
  'sync_cursors.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'publication_projections.published_by':
      'an administrator or director action, never a guest',
  'delist_requests.requested_by':
      'an administrator or director action, never a guest',
  'delist_requests.decided_by':
      'an administrator or director action, never a guest',
  'invitations.issued_by': 'the director who issued the invitation',
  'matrix_revisions.created_by': 'written by a director, never by a guest',
  'matrix_revisions.finalized_by': 'written by a director, never by a guest',
  'round_groups.locked_by': 'written by a director, never by a guest',
  're_flights.created_by': 'written by a director, never by a guest',
  're_flights.group_finalized_by': 'written by a director, never by a guest',
  're_flights.finalized_by': 'written by a director, never by a guest',
  're_flights.cancelled_by': 'written by a director, never by a guest',
  'matrix_assignments.actor_id': 'a director moving a pilot, never a guest',
  'score_placeholders.locked_by': 'written by a director, never by a guest',
  'official_scores.set_by': 'written by a director, never by a guest',
  'review_requests.decision_actor_id':
      'written by a director, never by a guest',
  'mutation_records.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'conflict_records.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'conflict_records.resolved_by': 'written by a director, never by a guest',
  'tombstones.owner_account_id':
      'names the owning director or installation owner, never a guest',
  'audit_events.owner_account_id':
      'names the owning director or installation owner, never a guest',
};
