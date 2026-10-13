# ConflictRecord

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md  
**Purpose:** Records two changes that collided on the same entity and could not be settled automatically, or that were settled with one set aside. It keeps both versions and the reason, so a decision, a review, and an audit can follow. It also marks a participant's submission that lost to the director's value but must be kept, as a silent record that needs no action.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** The contested entity (`entity_type` and `entity_id`)  
**Child entities:** None

## Relationships

- Belongs to one sync scope: a Contest (`contest_id`) or a director's data (`owner_account_id`)
- Links two MutationRecords: the one the service accepted, if any (`accepted_mutation_id`), and the competing one (`competing_mutation_id`)
- Referenced by an AuditEvent

## Fields/Properties

| Field                   | Type        | Required    | Default | Description                                                                                                                                                 |
| ----------------------- | ----------- | ----------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                    | UUIDv7      | Yes         | -       | Unique identifier for this conflict record                                                                                                                  |
| `contest_id`            | UUIDv7      | Conditional | -       | FK Contest. Exactly one of `contest_id` and `owner_account_id` is set                                                                                       |
| `owner_account_id`      | UUIDv7      | Conditional | -       | FK Account, for a conflict in the director's own data                                                                                                       |
| `entity_type`           | text        | Yes         | -       | Stable name of the entity type in conflict                                                                                                                  |
| `entity_id`             | UUIDv7      | Yes         | -       | Identifier of the entity in conflict                                                                                                                        |
| `accepted_mutation_id`  | UUIDv7      | No          | -       | FK MutationRecord of the change that was applied. Null while no change has been applied                                                                     |
| `competing_mutation_id` | UUIDv7      | Yes         | -       | FK MutationRecord of the change that collided with it                                                                                                       |
| `reason_code`           | text        | Yes         | -       | Machine-readable reason, for example `stale_base`, `unique_violation`, `director_over_participant`, `scored_assignment`                                     |
| `reason`                | text        | No          | -       | Human-readable explanation of why the conflict arose                                                                                                        |
| `requires_action`       | bool        | Yes         | true    | Whether the director has to decide. False for a silent record, which stays out of the list of conflicts that need action and notifies no one                |
| `resolution`            | enum        | Yes         | Pending | `Pending`, `Automatic`, or `Manual`                                                                                                                         |
| `resolution_choice`     | enum        | No          | -       | `KeptAccepted`, `TookCompeting`, or `Merged`. Set when resolved                                                                                             |
| `created_at`            | timestamptz | Yes         | now     | When the conflict was detected                                                                                                                              |
| `resolved_at`           | timestamptz | No          | -       | When resolution was completed                                                                                                                               |
| `resolved_by`           | UUIDv7      | No          | -       | FK Account that resolved it, for a manual resolution                                                                                                        |
| `accepted_payload`      | JSON        | No          | -       | The entity state the service applied. Null while no change has been applied. Kept so a side-by-side view needs no lookup of another installation's mutation |
| `competing_payload`     | JSON        | No          | -       | The entity state of the colliding mutation, as submitted                                                                                                    |
| `entity_revision`       | integer     | No          | -       | The entity's revision when the conflict was recorded, so a resolution can be based on it                                                                    |

## Invariants and Constraints

- Exactly one of `contest_id` and `owner_account_id` is set
- A conflict concerns two mutations on the same entity. Both versions are preserved
- Official contest authority takes precedence over participant submissions. The losing participant submission is retained and never overwritten or discarded
- A **silent record** has `requires_action` false and `resolution` `Automatic`. It is created when a participant's submission loses to the director's value for the same score. The submission remains an immutable ScoreAttempt, appears in the score's history, does not block synchronization, and is not turned into a review request or notification. It stays inert until the director separately opens a review
- Only an automatic resolution may be applied by the service. A manual decision is recorded for audit
- A conflict with no applicable rule stays `Pending` with `requires_action` true until a person decides
- A pending review request whose base revision was changed by a director's offline edit is handled as a decision on the review, not as a conflict record
- A record is immutable once its resolution is final

## Lifecycle

Created by the service when it detects a conflict. Resolved over time until settled. Retained indefinitely for audit.

## Privacy and Scope

Visible to the contest's director and their installations. Participants do not see conflict records.

## Audit and Synchronization

Created by the service. The resolution fields are updated as the conflict is settled, and each decision is audited.
