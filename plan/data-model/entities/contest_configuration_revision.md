# ContestConfigurationRevision

**Relationship to architecture-requirements:** [contest.md](../../architecture-requirements/data/contest.md), [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Revisioned contest configuration overrides linked to official discipline profile. Overrides are versioned so historical results remain reproducible when config changes.
**Identifier:** `revision_id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** None

## Relationships

- References a DisciplineProfile (stable profile)
- Linked from ScoreAttempt, OfficialScore, ScoreCalculationResult (for provenance)
- One active revision per Contest; older revisions immutable

## Fields/Properties

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `revision_id` | UUIDv7 | Yes | — | Primary key (surrogate) |
| `contest_id` | UUIDv7 | Yes | — | FK → Contest |
| `profile_id` | UUIDv7 | Yes | — | FK → DisciplineProfile |
| `profile_version` | int | Yes | — | Version of DisciplineProfile at time of creation |
| `config_json` | string | Yes | — | JSON blob of full config overrides |
| `created_by` | UUIDv7 | Yes | — | Actor who created the revision |
| `notes` | string | No | — | Free-text notes about the revision |
| `created_at` | ISO 8601 | Yes | — | Timestamp of creation |
| `replaces_revision` | UUIDv7 | No | — | FK → previous ContestConfigurationRevision |
| `current` | bool | Yes | true | Whether this is the active revision |

## Invariants and Constraints

- One revision must be marked current at all times (exactly one)
- Older revisions cannot be mutated
- Any change to config creates a new revision; never update `config_json` in place
- `profile_version` must match an existing DisciplineProfile version at time of creation

## Lifecycle

1. Initially create from latest default profile for the chosen discipline
2. Director edits config → create new revision marked current, mark old as not current
3. When contest is completed, config locked (no new revisions)

## Privacy and Scope

- Config overrides are private
- Not exposed in public projection, except indirectly through scoring behavior

## Audit and Synchronization

- All mutations create an AuditEvent with base version
- Old revisions are not deleted (preserved for provenance)
- MutationRecord includes config revision number in provenance metadata