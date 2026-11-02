/// Indexes (mostly unique) that a table definition cannot express: they use an
/// expression (`lower(...)`, `COALESCE(...)`) or a `WHERE` clause. Plain SQL
/// that SQLite and PostgreSQL both accept, kept here so there is one place to
/// read and test them. The migration runs them after the table is created.
const customIndexes = <String, List<String>>{
  'publication_identities': [
    // The public listing filters on visibility and orders by contest start.
    'CREATE INDEX publication_identities_listing ON publication_identities '
        '(visibility, contest_starts_at DESC)',
  ],
  'accounts': [
    // Exactly one account stands in for erased users.
    "CREATE UNIQUE INDEX accounts_one_deleted ON accounts (kind) WHERE kind = 'deleted'",
  ],
  'participant_account_links': [
    // A profile has at most one confirmed link at a time.
    'CREATE UNIQUE INDEX participant_account_links_one_confirmed ON '
        'participant_account_links (participant_profile_id) '
        "WHERE status = 'Confirmed'",
  ],
  'installation_activations': [
    // The first release has one administrator installation per contest.
    'CREATE UNIQUE INDEX installation_activations_one_open ON '
        'installation_activations (contest_id) WHERE ended_at IS NULL',
  ],
  'delist_requests': [
    // At most one pending request per publication.
    'CREATE UNIQUE INDEX delist_requests_one_pending ON delist_requests '
        "(publication_id) WHERE state = 'pending'",
  ],
  'invitations': [
    // At most one active invitation per participation.
    'CREATE UNIQUE INDEX invitations_one_active ON invitations '
        "(contest_participation_id) WHERE state = 'Active'",
  ],
  'matrix_revisions': [
    // At most one finalized revision extends any given revision; the first
    // revision has no predecessor, so a missing one counts as one value.
    'CREATE UNIQUE INDEX matrix_revisions_one_finalized_successor ON '
        "matrix_revisions (contest_id, COALESCE(previous_revision_id, '')) "
        'WHERE finalized_at IS NOT NULL',
  ],
  'rounds': [
    // A round ordinal is taken once among rounds that are still in play.
    'CREATE UNIQUE INDEX rounds_live_ordinal ON rounds (contest_id, ordinal) '
        "WHERE superseded_by_round_id IS NULL AND status <> 'Cancelled'",
  ],
  'matrix_assignments': [
    // A lane holds one pilot per group, among assignments not moved away.
    'CREATE UNIQUE INDEX matrix_assignments_live_lane ON matrix_assignments '
        '(scheduled_round_id, "group", lane) '
        'WHERE lane IS NOT NULL AND superseded_by_assignment_id IS NULL',
    // A pilot flies a credited round once through the matrix.
    'CREATE UNIQUE INDEX matrix_assignments_live_participation ON '
        'matrix_assignments (contest_participation_id, credited_round_id) '
        "WHERE superseded_by_assignment_id IS NULL AND assignment_type IN "
        "('Original', 'Moved', 'LateAdd')",
  ],
  'review_requests': [
    // One open review request per score.
    'CREATE UNIQUE INDEX review_requests_one_open ON review_requests '
        "(score_placeholder_id) WHERE state IN ('Submitted', 'UnderReview')",
  ],
  'roles': [
    // System roles (no owner) share one namespace, so a missing owner counts
    // as one value.
    'CREATE UNIQUE INDEX roles_owner_display_name ON roles '
        "(COALESCE(owner_account_id, ''), lower(display_name))",
    // Exactly one role is the Pilot role.
    "CREATE UNIQUE INDEX roles_one_pilot ON roles (type) WHERE type = 'Pilot'",
  ],
  'contest_configuration_presets': [
    'CREATE UNIQUE INDEX contest_configuration_presets_owner_name ON '
        'contest_configuration_presets (owner_account_id, lower(name))',
  ],
  'model_catalogs': [
    // Entries without a manufacturer are unique by name within a profile.
    'CREATE UNIQUE INDEX model_catalogs_profile_name_manufacturer ON '
        'model_catalogs (participant_profile_id, lower(name), '
        "lower(COALESCE(manufacturer, '')))",
  ],
  'discipline_formulas': [
    // Only one formula per profile version is the primary one.
    'CREATE UNIQUE INDEX discipline_formulas_one_primary ON '
        'discipline_formulas (discipline_profile_id) WHERE is_primary',
  ],
};
