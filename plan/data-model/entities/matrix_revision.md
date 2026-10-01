# MatrixRevision

**Relationship to architecture-requirements:** `plan/architecture-requirements/data/matrix-and-assignments.md`
**Purpose:** Records the draw configuration, participating pilot links, rounds, groups, lanes, random seed or reproducibility data, fairness result, creator, reason, and finalization state. A new draw never overwrites an earlier revision.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** Round, Group

## Relationships

Belongs to a Contest; parent of Round; a Round belongs to a MatrixRevision and has an ordinal round number.

## Fields/Properties

| Field                                      | Type                      | Required | Default | Description                                                  |
| ------------------------------------------ | ------------------------- | -------- | ------- | ------------------------------------------------------------ |
| `id`                                       | UUIDv7                    | Yes      | -       | Primary key                                                  |
| `contest_id`                               | UUID                      | Yes      | -       | FK to Contest                                                |
| `config`                                   | JSON                      | Yes      | -       | Draw configuration, fairness rules, and reproducibility data |
| `participating_participant_participations` | Array[UUID]               | Yes      | -       | Link IDs included in this draw                               |
| `rounds`                                   | Array[Int]                | Yes      | -       | Ordinal round numbers in this matrix                         |
| `groups`                                   | Array[Int]                | Yes      | -       | Ordinal group numbers in this matrix                         |
| `lanes`                                    | Array[Int]                | Yes      | -       | Lane numbers available in this matrix                        |
| `random_seed`                              | BigInt                    | No       | -       | Seed used for reproducibility of the seeded draw             |
| `fairness_result`                          | JSON                      | No       | -       | Result from the draw fairness algorithm                      |
| `creator_id`                               | UUID                      | Yes      | -       | FK to Agent who created this revision                        |
| `reason`                                   | String                    | No       | -       | Explanation for this revision                                |
| `finalizing_agent`                         | Enum(Director, Assistant) | No       | -       | Role of the agent who finalized                              |
| `finalized`                                | Bool                      | No       | false   | Whether this revision is finalized                           |
| `revision`                                 | Int                       | Yes      | -       | Incremental revision number for this contest's matrix        |

## Invariants and Constraints

- A new draw never overwrites an earlier revision.
- Seeded draw mode may create later matrix revisions incrementally after prerequisite rounds are complete.
- Future unscored rounds may be added or revised only under the contest lifecycle and explicit matrix revision rules.

## Lifecycle

Draft → Finalized (by Director or Assistant). Once finalized, a score placeholder is created for each pilot assignment.

## Privacy and Scope

Internal to contest management. The draw seed, fairness result, and reason are private to organizers; the matrix layout (rounds, groups, lanes) becomes public after the draw is announced.

## Audit and Synchronization

Every matrix revision is immutable once created. Mutations are additive — a new revision supersedes prior versions without altering them. Idempotent operations: re-querying the latest revision after finalization always returns the same finalized revision.
