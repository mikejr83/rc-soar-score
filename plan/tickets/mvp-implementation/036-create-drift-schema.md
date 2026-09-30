# Ticket 036 — Creation of Drift Table Schema

- **Category:** Data / Persistence
- **Priority:** High
- **Status:** Open

## Context

Per the architectural decision documented in `plan/architecture-requirements/data/README.md`, the data layer uses PostgreSQL for the backend and IndexedDB/SQLite for clients, with a uniform relational model. We are using Drift (SQLite) as the ORM layer through QueryExecutor for portability between backends.

The conceptual data model is fully specified. The `packages/soar_score_data` database currently only has the `Contests` table. All other entities must be defined before the server API routes can be implemented.

## Table Definitions

Create one Drift `Table` per entity, following the existing conventions in `packages/soar_score_data`. All files go in `lib/` with singular names. Use `uuid` type from the `uuid` package or generate via `Id`.

### Identity and Ownership

**`accounts` table** (`accounts_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `first_name` TEXT NOT NULL
- `last_name` TEXT NOT NULL
- `email_address` TEXT NOT NULL UNIQUE
- `idp_subject` TEXT NOT NULL UNIQUE
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

**`participation_links` table** (`participation_links_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `participant_profile_id` TEXT NOT NULL REFERENCES `participant_profiles`
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `class_` TEXT NOT NULL
- `role_ref` TEXT NOT NULL REFERENCES `roles`
- `role_type` TEXT NOT NULL
- `participant_number` INTEGER
- `team_ref` TEXT REFERENCES `teams`
- `scoring_uuid` TEXT NOT NULL UNIQUE
- `privacy_overrides` TEXT
- `status` TEXT NOT NULL
- `retired_at_round` INTEGER
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- UNIQUE (`contest_id`, `participant_profile_id`)

**`roles` table** (`roles_table.dart`):
- `id` TEXT PRIMARY KEY
- `name` TEXT NOT NULL
- `role_type` TEXT NOT NULL
- `is_system_default` BOOLEAN NOT NULL DEFAULT false
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

**`participant_account_links` table** (`participant_account_links_table.dart`):
- `id` TEXT PRIMARY KEY
- `participant_profile_id` TEXT NOT NULL REFERENCES `participant_profiles`
- `account_id` TEXT NOT NULL REFERENCES `accounts`
- `consent_given` BOOLEAN NOT NULL DEFAULT false
- `consent_timestamp` TEXT
- `created_at` TEXT NOT NULL
- UNIQUE (`participant_profile_id`, `account_id`)

### Contest Participation and Teams

**`participant_profiles` table** (`participant_profiles_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `first_name` TEXT NOT NULL
- `last_name` TEXT NOT NULL
- `club` TEXT
- `fai_number` TEXT
- `national_org_id` TEXT
- `city` TEXT
- `state_province` TEXT
- `country` TEXT
- `email` TEXT
- `owned_by_account_id` TEXT REFERENCES `accounts`
- `is_shared` BOOLEAN NOT NULL DEFAULT false
- `privacy_policy` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

**`teams` table** (`teams_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `name` TEXT NOT NULL
- `scoring_pilot_count` INTEGER NOT NULL DEFAULT 1
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- UNIQUE (`contest_id`, `name`)

**`team_memberships` table** (`team_memberships_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `team_id` TEXT NOT NULL REFERENCES `teams`
- `participation_link_id` TEXT NOT NULL REFERENCES `participation_links`
- `role` TEXT
- `joined_at` TEXT NOT NULL
- UNIQUE (`team_id`, `participation_link_id`)

### Models

**`model_catalogs` table** (`model_catalogs_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `name` TEXT NOT NULL
- `manufacturer` TEXT
- `model_identifier` TEXT
- `owned_by_account_id` TEXT REFERENCES `accounts`
- `is_shared` BOOLEAN NOT NULL DEFAULT false
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

**`contest_model_links` table** (`contest_model_links_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `participation_link_id` TEXT NOT NULL REFERENCES `participation_links`
- `model_catalog_id` TEXT REFERENCES `model_catalogs`
- `model_name` TEXT
- `manufacturer` TEXT
- `model_identifier` TEXT
- `created_at` TEXT NOT NULL
- UNIQUE (`contest_id`, `participation_link_id`)

### Disciplines and Configuration

**`discipline_profiles` table** (`discipline_profiles_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `discipline_type` TEXT NOT NULL
- `rules_version` TEXT NOT NULL
- `name` TEXT NOT NULL
- `config_fields` TEXT NOT NULL
- `score_entry_fields` TEXT NOT NULL
- `validation_rules` TEXT NOT NULL
- `zero_reasons` TEXT NOT NULL
- `formulas` TEXT NOT NULL
- `normalization_rules` TEXT NOT NULL
- `rounding_rules` TEXT NOT NULL
- `calculation_metadata` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- UNIQUE (`discipline_type`, `rules_version`)

**`contest_config_revisions` table** (`contest_config_revisions_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `discipline_profile_id` TEXT NOT NULL REFERENCES `discipline_profiles`
- `rules_version` TEXT NOT NULL
- `group_score_mode` TEXT NOT NULL
- `rounding` TEXT NOT NULL
- `dropped_round_policy` TEXT NOT NULL
- `target_time` TEXT
- `points_per_second` REAL
- `discipline_settings` TEXT
- `matrix_revision_id` TEXT REFERENCES `matrix_revisions`
- `score_revision_id` TEXT
- `calculation_version` TEXT NOT NULL
- `created_by` TEXT
- `created_from_base_revision` TEXT
- `is_current` BOOLEAN NOT NULL DEFAULT false
- `created_at` TEXT NOT NULL
- UNIQUE (`contest_id`, `score_revision_id`)

**`landing_tables` table** (`landing_tables_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `discipline_profile_id` TEXT NOT NULL REFERENCES `discipline_profiles`
- `name` TEXT NOT NULL
- `revision` INTEGER NOT NULL DEFAULT 1
- `input_unit` TEXT NOT NULL
- `entries` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- UNIQUE (`discipline_profile_id`, `name`, `revision`)

### Matrix and Assignments

**`matrix_revisions` table** (`matrix_revisions_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `draw_config` TEXT NOT NULL
- `participated_participant_link_ids` TEXT NOT NULL
- `seed` TEXT
- `fairness_result` TEXT
- `created_by` TEXT
- `created_from_base_revision` TEXT
- `reason` TEXT
- `is_final` BOOLEAN NOT NULL DEFAULT false
- `calculation_version` TEXT NOT NULL
- `created_at` TEXT NOT NULL

**`rounds` table** (`rounds_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `round_number` INTEGER NOT NULL
- `created_at` TEXT NOT NULL
- UNIQUE (`matrix_revision_id`, `round_number`)

**`groups` table** (`groups_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `round_id` TEXT NOT NULL REFERENCES `rounds`
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `group_number` INTEGER NOT NULL
- `created_at` TEXT NOT NULL
- UNIQUE (`round_id`, `group_number`)

**`assignments` table** (`assignments_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `participation_link_id` TEXT NOT NULL REFERENCES `participation_links`
- `scheduled_round_id` TEXT NOT NULL REFERENCES `rounds`
- `credited_round_id` TEXT NOT NULL REFERENCES `rounds`
- `group_id` TEXT NOT NULL REFERENCES `groups`
- `lane` INTEGER NOT NULL
- `assignment_type` TEXT NOT NULL
- `source_assignment_id` TEXT REFERENCES `assignments`
- `actor_id` TEXT
- `reason` TEXT
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- UNIQUE (`matrix_revision_id`, `participation_link_id`, `scheduled_round_id`)

### Scores and Results

**`score_placeholders` table** (`score_placeholders_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `assignment_id` TEXT NOT NULL REFERENCES `assignments`
- `participation_link_id` TEXT NOT NULL REFERENCES `participation_links`
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `scheduled_round_id` TEXT NOT NULL REFERENCES `rounds`
- `credited_round_id` TEXT NOT NULL REFERENCES `rounds`
- `group_id` TEXT NOT NULL REFERENCES `groups`
- `flight_attempt` INTEGER NOT NULL
- `state` TEXT NOT NULL DEFAULT 'NotEntered'
- `created_at` TEXT NOT NULL
- UNIQUE (`assignment_id`, `flight_attempt`)

**`score_attempts` table** (`score_attempts_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `placeholder_id` TEXT NOT NULL REFERENCES `score_placeholders`
- `raw_components` TEXT
- `cumulative_penalty` INTEGER NOT NULL DEFAULT 0
- `zero_reason` TEXT
- `status_reason` TEXT
- `actor_id` TEXT
- `authority` TEXT
- `source_device_id` TEXT
- `client_mutation_id` TEXT
- `accepted_at` TEXT
- `base_score_revision` TEXT
- `contest_config_revision_id` TEXT NOT NULL REFERENCES `contest_config_revisions`
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `discipline_rules_version` TEXT NOT NULL
- `calculation_version` TEXT NOT NULL
- UNIQUE (`client_mutation_id`)

**`calculation_results` table** (`calculation_results_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `score_attempt_id` TEXT NOT NULL REFERENCES `score_attempts`
- `placeholder_id` TEXT NOT NULL REFERENCES `score_placeholders`
- `contest_total` REAL
- `dropped_round` REAL
- `rank` INTEGER
- `team_total` REAL
- `contest_config_revision_id` TEXT NOT NULL REFERENCES `contest_config_revisions`
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `discipline_rules_version` TEXT NOT NULL
- `calculation_version` TEXT NOT NULL
- `calculation_metadata` TEXT
- `created_at` TEXT NOT NULL
- UNIQUE (`score_attempt_id`)

### Reviews and Locks

**`score_locks` table** (`score_locks_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `scope_type` TEXT NOT NULL
- `scope_id` TEXT
- `locked_at` TEXT NOT NULL
- `locked_by` TEXT
- `reason` TEXT
- UNIQUE (`contest_id`, `scope_type`, `scope_id`)

**`review_requests` table** (`review_requests_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `placeholder_id` TEXT NOT NULL REFERENCES `score_placeholders`
- `current_score` TEXT
- `proposed_raw_components` TEXT
- `proposed_cumulative_penalty` INTEGER
- `message` TEXT
- `requester_id` TEXT NOT NULL
- `base_score_revision` TEXT
- `status` TEXT NOT NULL DEFAULT 'Submitted'
- `decision_actor` TEXT
- `decision_message` TEXT
- `submitted_at` TEXT NOT NULL
- `decided_at` TEXT

### Invitations

**`invitations` table** (`invitations_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `participation_link_id` TEXT NOT NULL REFERENCES `participation_links`
- `credential_hash` TEXT NOT NULL
- `credential_expiry` TEXT
- `invitation_revision` INTEGER NOT NULL DEFAULT 1
- `delivery_outcomes` TEXT
- `created_at` TEXT NOT NULL
- `revocation_at` TEXT
- UNIQUE (`contest_id`, `participation_link_id`, `invitation_revision`)

### Publication

**`published_contests` table** (`published_contests_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `source_contest_id` TEXT NOT NULL REFERENCES `contests`
- `email` TEXT
- `owner_account_id` TEXT REFERENCES `accounts`
- `published_contest_uuid` TEXT NOT NULL
- `visibility` TEXT NOT NULL DEFAULT 'Private'
- `published_at` TEXT NOT NULL
- `claimed_at` TEXT
- UNIQUE (`source_contest_id`)
- UNIQUE (`published_contest_uuid`)

**`publication_revisions` table** (`publication_revisions_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `published_contest_id` TEXT NOT NULL REFERENCES `published_contests`
- `contest_info_json` TEXT NOT NULL
- `calculation_metadata` TEXT
- `source_contest_revision` TEXT NOT NULL
- `contest_config_revision_id` TEXT NOT NULL REFERENCES `contest_config_revisions`
- `matrix_revision_id` TEXT NOT NULL REFERENCES `matrix_revisions`
- `discipline_rules_version` TEXT NOT NULL
- `calculation_version` TEXT NOT NULL
- `published_at` TEXT NOT NULL
- `published_by` TEXT
- UNIQUE (`published_contest_id`, `source_contest_revision`)

### Synchronization and Audit

**`entity_mutations` table** (`entity_mutations_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `entity_type` TEXT NOT NULL
- `entity_id` TEXT NOT NULL
- `base_revision` TEXT NOT NULL
- `new_revision` TEXT
- `payload` TEXT NOT NULL
- `actor_id` TEXT
- `authority` TEXT
- `source_installation_id` TEXT
- `client_time` TEXT NOT NULL
- `server_acceptance_time` TEXT
- `status` TEXT NOT NULL DEFAULT 'Pending'
- `accepted_on_installation_id` TEXT
- `created_at` TEXT NOT NULL
- UNIQUE (`entity_id`, `client_time`)

**`sync_conflicts` table** (`sync_conflicts_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `entity_type` TEXT NOT NULL
- `entity_id` TEXT NOT NULL
- `installation_id` TEXT
- `mutation_id` TEXT NOT NULL
- `conflicting_mutation_id` TEXT NOT NULL
- `conflict_reason` TEXT NOT NULL
- `resolution_status` TEXT NOT NULL
- `resolved` TEXT
- `created_at` TEXT NOT NULL
- `resolved_at` TEXT

### Audit Events

**`audit_events` table** (`audit_events_table.dart`):
- `id` TEXT PRIMARY KEY (UUIDv7)
- `contest_id` TEXT NOT NULL REFERENCES `contests`
- `entity_id` TEXT
- `entity_type` TEXT NOT NULL
- `category` TEXT NOT NULL
- `action` TEXT NOT NULL
- `actor_id` TEXT
- `authority` TEXT
- `source_installation_id` TEXT
- `source_device` TEXT
- `base_revision` TEXT
- `result_revision` TEXT
- `server_timestamp` TEXT
- `client_timestamp` TEXT
- `reason` TEXT
- `result` TEXT
- `details` TEXT
- `created_at` TEXT NOT NULL

## Contests Table Expansion

Update `packages/soar_score_data/lib/contests_table.dart` to include all contest fields per `contest.md` architecture specification:
- Expand to full contest model with ownerAccountId, dates, venue info, timezone
- **Add separate columns for each state dimension** (no combined status enum, per architecture decision):
  - `execution_lifecycle` TEXT NOT NULL DEFAULT 'Created'
  - `scoring_access_open` BOOLEAN NOT NULL DEFAULT false
  - `administration_locked` BOOLEAN NOT NULL DEFAULT false
  - `published` BOOLEAN NOT NULL DEFAULT false
  - `visibility` TEXT NOT NULL DEFAULT 'Unpublished'
  - `archived` BOOLEAN NOT NULL DEFAULT false
  - `deletion_status` TEXT NOT NULL DEFAULT 'None'
- Add revision tracking: `revision` INTEGER NOT NULL DEFAULT 1

## Database Configuration Update

Update `packages/soar_score_data/lib/database.dart` to:
1. Register all new tables with `@DriftDatabase(tables: [...])`
2. Update `schemaVersion` from 1 to 2
3. Add migration `migrateToVersion2` in `lib/migrate.dart` that creates all new tables with proper foreign keys
4. Keep `onCreate` handling both version 1 and 2 scenarios (direct creation from scratch should use latest schema)

## Generated Files

Run `dart run build_runner build` to regenerate `database.g.dart` with all entities.

## Tests

Add tests in `lib/test/` for table schema validation, migration paths, and basic insert/select/readback for each table (minimum one CRUD test per entity type).

## Acceptance Criteria

- [ ] All drift table definitions created following established conventions
- [ ] Contests table expanded with full architecture-specified fields
- [ ] All entities have proper foreign key references and cascade deletes
- [ ] All entities have appropriate indexes on foreign keys and lookup columns
- [ ] Database schema version updated and migrations defined
- [ ] `dart run build_runner build` completes without errors
- [ ] `dart analyze` passes with no warnings in `soar_score_data`
- [ ] CRUD test for each entity type passes

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md) — Database infrastructure already exists
- [016-scaffold-data-postgres-package.md](016-scaffold-data-postgres-package.md) — PostgreSQL support in place
- [035-create-data-models.md](035-create-data-models.md) — Dart domain models (recommended for type safety in repositories)

## Sources

- `plan/architecture-requirements/data/README.md` — Data model architecture
- `plan/architecture-requirements/data/contest.md` — Contest entity details
- `plan/architecture-requirements/data/participants.md` — Participant data model
- `packages/soar_score_data/lib/contests_table.dart` — Existing table pattern
- `packages/soar_score_data/lib/database.dart` — Database configuration pattern
