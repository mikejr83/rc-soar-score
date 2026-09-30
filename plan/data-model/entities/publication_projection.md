# PublicationProjection

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md
**Purpose:** An atomic, immutable snapshot of a contest's public data at a specific publish time, providing complete revision semantics for readers.
**Identifier:** `projection_id` (UUIDv7)
**Parent entity:** PublicationIdentity
**Child entities:** None

## Relationships
- One PublicationIdentity publishes zero or more PublicationProjection revisions (one-to-many)
- Each projection is a unique, versioned snapshot
- `result` field distinguishes successful Published projections from Failed attempts

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `projection_id` | UUIDv7 | yes | - | Unique identifier for this projection revision |
| `publication_id` | UUIDv7 | yes | - | FK to the parent PublicationIdentity |
| `source_contest_revision` | integer | yes | - | Source contest revision number at publish time |
| `source_config_revision` | integer | yes | - | Source configuration revision number |
| `source_matrix_revision` | integer | yes | - | Source score matrix revision number |
| `discipline_rules_version` | string | yes | - | Version of discipline rules used |
| `calculation_version` | string | yes | - | Version of calculation engine used |
| `contest_identity` | object | yes | - | Snapshot of contest identity and dates for display |
| `dates` | object | no | null | Contested period dates |
| `host_location` | object | no | null | Host and geographic location data |
| `participant_display_data` | array | no | null | Permitted participant display data |
| `teams` | array | no | null | Permitted team display data when applicable |
| `matrix_info` | object | no | null | Score matrix information |
| `scores` | array | no | null | Computed scores |
| `rankings` | array | no | null | Computed rankings |
| `calculation_metadata` | object | no | null | Calculation metadata and provenance |
| `published_at` | datetime | yes | - | Timestamp of publication |
| `published_by` | UUIDv7 | yes | - | Identifier of the actor who published |
| `result` | Enum [Published, Failed] | yes | Published | Outcome of the publish attempt |

## Invariants and Constraints
- Each projection is an atomic, immutable snapshot created at publish time
- Once created, a projection must never be modified (append-only history)
- Failed or stale publish attempts are retained in audit history but change neither private data nor the current projection
- Readers always see either the previous complete revision or the new complete revision - never partial updates
- Participant email, invitation credentials, pending mutations, review details, raw private inputs, and director-only audit data are excluded unless separately permitted

## Lifecycle
- Publish attempt -> Successful publish: creates new immutable projection; updates `current_projection_id` on the parent identity
- Publish attempt -> Failed/stale publish: retained in audit history; no effect on private data or current projection
- No in-place updates; changes require a new projection revision

## Privacy and Scope
- Projections are entirely public-facing data derived from the private contest
- Once a publication's visibility is set to Public, its current projection is readable by unauthenticated users
- `participant_display_data` and `teams` may contain public display data but exclude private fields (emails, credentials)

## Audit and Synchronization
- Each publication attempt, whether successful or failed, is recorded in the publication's audit history
- A successful publish updates the parent PublicationIdentity's `published_at` and `current_projection_id`
- Atomicity guarantees: the projection is never partially visible to readers
- Idempotent under identical source revisions: re-publishing with no changes yields an equivalent projection