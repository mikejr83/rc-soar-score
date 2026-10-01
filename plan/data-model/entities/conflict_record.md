# ConflictRecord

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md
**Purpose:** Captures conflicts that arise during synchronization where automatic resolution rules could not decide, records which party won, and preserves the losing version so that review, audit, and recalculation can proceed.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Contested entity (entityType + entityId)
**Child entities:** None

## Relationships

Links two MutationRecords (`winner_mutation_id` and `loser_mutation_id`). Tied to the entity on which they disagree. An audit event references this record.

## Fields/Properties

| Field              | Type                          | Required | Default   | Description                                               |
| ------------------ | ----------------------------- | -------- | --------- | --------------------------------------------------------- |
| id                 | UUIDv7                        | Yes      | —         | Unique identifier for this conflict record                |
| entity_type        | text                          | Yes      | —         | Stable name of the entity type in conflict                |
| entity_id          | text                          | Yes      | —         | Stable identifier of the entity in conflict               |
| contest_id         | FK(Contest.contestId)         | No       | NULL      | Scope when the entity belongs to a contest                |
| winner_mutation_id | FK(MutationRecord.mutationId) | No       | NULL      | Accepted mutation record                                  |
| loser_mutation_id  | FK(MutationRecord.mutationId) | No       | NULL      | Rejected/conflicting mutation record                      |
| reason             | text                          | Yes      | —         | Explanation of why the conflict occurred                  |
| resolution         | text                          | Yes      | 'Pending' | Current state of the conflict: Pending, Manual, Automatic |
| resolved_at        | timestamp                     | No       | NULL      | When resolution first completed                           |
| resolved_by        | FK(User.userId)               | No       | NULL      | Actor who resolved the conflict (if manual)               |

## Invariants and Constraints

- A conflict exists between precisely two mutations on the same entity.
- Losing participant submissions are retained and never overwritten or discarded.
- Official contest authority takes precedence over participant submissions.
- Conflicts with no applicable resolution rule remain Pending until a human decides.
- Only Automatic resolution may be applied by the service; Manual decisions are recorded for audit.

## Lifecycle

Created when the service detects a conflict it cannot auto-resolve. Resolution may be updated over time until settled. Retained indefinitely for audit.

## Privacy and Scope

Visible to contest installations and officials.

## Audit and Synchronization

Created by the service when detecting an unresolvable conflict. Resolution fields updated as the conflict is resolved. The record is immutable once resolution is final.
