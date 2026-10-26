# PublicationProjection

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md, plan/architecture-requirements/contest-publishing.md  
**Purpose:** An atomic, immutable snapshot of a contest's public data at a specific publish time, providing complete revision semantics for readers. One row exists per successful publish. Failed and rejected attempts are recorded as AuditEvents, not as projections.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** PublicationIdentity  
**Child entities:** None

## Relationships

- Belongs to a [PublicationIdentity](publication_identity.md) (`publication_id`). One identity has many projection revisions
- Pilots in the content are referenced only by `pilot_key`, which resolves to a [PublicationParticipant](publication_participant.md). The key is a value in the content, not a foreign key
- Records the source contest, configuration, and matrix revisions as plain numbers, not foreign keys, because the contest may be deleted while the projection remains
- The publication's `current_projection_id` points at the latest projection

## Fields/Properties

| Field                      | Type        | Required | Default | Description                                                                                                                                                                                        |
| -------------------------- | ----------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7      | Yes      | -       | Unique identifier for this projection revision                                                                                                                                                     |
| `publication_id`           | UUIDv7      | Yes      | -       | FK PublicationIdentity                                                                                                                                                                             |
| `projection_revision`      | Integer     | Yes      | -       | Sequential number of this projection within the publication, starting at 1                                                                                                                         |
| `contest_revision`         | Integer     | Yes      | -       | Source contest revision number at publish time                                                                                                                                                     |
| `config_revision`          | Integer     | Yes      | -       | Source configuration revision number                                                                                                                                                               |
| `matrix_revision`          | Integer     | Yes      | -       | Source matrix revision number                                                                                                                                                                      |
| `discipline_type`          | Enum        | Yes      | -       | Discipline of the contest (ALES, ThermalDuration, F3J, F5J, F3L, F3K)                                                                                                                              |
| `discipline_rules_version` | Integer     | Yes      | -       | Version of the discipline profile used                                                                                                                                                             |
| `calculation_version`      | String      | Yes      | -       | Version of the calculation engine used                                                                                                                                                             |
| `contest_identity`         | JSON        | Yes      | -       | Name, start and end dates, time zone, host and location, and the publicly shown discipline name                                                                                                    |
| `participants`             | JSON        | No       | null    | One entry per pilot: `pilot_key` and non-identifying display data (class, number, team key). Names and other identifying details are never embedded; they live in PublicationParticipant           |
| `teams`                    | JSON        | No       | null    | Team display data when teams are used: team key, name, member `pilot_key` list                                                                                                                     |
| `matrix_info`              | JSON        | No       | null    | Rounds, groups, lanes, and each pilot's assignments                                                                                                                                                |
| `scores`                   | JSON        | No       | null    | Round scores per pilot. Each entry carries `raw_components`: the official score's values for the discipline's published score fields (see `calculation_metadata.score_fields`), keyed by field key |
| `standings`                | JSON        | No       | null    | Overall scores and placing for pilots and teams after each completed round, so the site can show them as of any round                                                                              |
| `calculation_metadata`     | JSON        | No       | null    | Calculation metadata and provenance needed to explain the displayed results, including `score_fields` (key, name, type, unit and precision of each published raw component)                        |
| `published_at`             | timestamptz | Yes      | -       | When the projection was published                                                                                                                                                                  |
| `published_by`             | UUIDv7      | No       | -       | FK Account that published. Null for an anonymous publish, which is identified by the publication's `verification_email`                                                                            |
| `client_mutation_id`       | String      | Yes      | -       | Idempotency key for the publish request. Unique within the publication                                                                                                                             |

## Invariants and Constraints

- (`publication_id`, `projection_revision`) is unique, and the revision of a new projection is one higher than the publication's latest
- (`publication_id`, `client_mutation_id`) is unique. A retried publish returns the existing projection and creates no second one
- Each projection is an atomic, immutable snapshot created at publish time. Once created it is never modified
- Failed or stale publish attempts create no projection. They are retained as `PublicationAttempt` AuditEvents and change neither private data nor the current projection
- Readers always see either the previous complete revision or the new complete revision, never a partial update
- Content identifies pilots by `pilot_key` only. Participant email, invitation credentials, pending mutations, review details, raw private inputs, and director-only audit data are never included unless a separate requirement permits them
- `standings` holds the overall results after each completed round. While the publication's results are hidden, the service returns standings only up to `results_hidden_through_round`. The filtering is done by the service, so withheld data never reaches the client
- Redaction of a pilot's details never changes any projection
- Projections are retained for as long as the publication is. Deleting the source contest does not delete them

## Lifecycle

- Successful publish: creates a new immutable projection and sets the publication's `current_projection_id` to it
- Failed or stale publish: no projection. An AuditEvent records the attempt with the source revision and actor
- There are no in-place updates. A change requires a new projection revision

## Privacy and Scope

- Projections are entirely public-facing data derived from the private contest
- Once the publication's visibility is `Public`, or `Unlisted` for someone with the link, its current projection is readable without an account. A `Delisted` publication's projections are not readable by the public
- `participants` and `teams` contain public display data only and exclude private fields
- Backend and publication only. Not synchronized to installations

## Audit and Synchronization

- Each publication attempt, successful or not, is recorded as a `PublicationAttempt` AuditEvent tied to `publication_id`
- A successful publish updates the parent PublicationIdentity's `published_at` (first publish only) and `current_projection_id`
- Atomicity guarantees: the projection is never partially visible to readers
- Idempotent under identical source revisions and request: republishing with no changes yields an equivalent projection and the same acknowledgement
