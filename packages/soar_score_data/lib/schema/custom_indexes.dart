/// Unique indexes that a table definition cannot express: they use an
/// expression (`lower(...)`, `COALESCE(...)`) or a `WHERE` clause. Plain SQL
/// that SQLite and PostgreSQL both accept, kept here so there is one place to
/// read and test them. The migration runs them after the table is created.
const customIndexes = <String, List<String>>{
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
    // Entries without a manufacturer are unique by name within an owner.
    'CREATE UNIQUE INDEX model_catalogs_owner_name_manufacturer ON '
        "model_catalogs (owner_account_id, name, COALESCE(manufacturer, ''))",
  ],
  'discipline_formulas': [
    // Only one formula per profile version is the primary one.
    'CREATE UNIQUE INDEX discipline_formulas_one_primary ON '
        'discipline_formulas (discipline_profile_id) WHERE is_primary',
  ],
};
