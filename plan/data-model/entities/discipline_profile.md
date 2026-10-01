# DisciplineProfile

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Stores the identity, metadata, and lifecycle state for a versioned official scoring profile of a soaring discipline. All rules (config fields, score entry fields, formulas, validation, zero reasons, etc.) are stored in child entities keyed by `discipline_profile_id` and `version`.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** DisciplineConfigField, DisciplineScoreField, DisciplineValidation, DisciplineFormula, DisciplineRule

## Fields/Properties

| Field           | Type                                            | Required | Default | Description                                                           |
| --------------- | ----------------------------------------------- | -------- | ------- | --------------------------------------------------------------------- |
| `id`            | PK                                              | Yes      | —       | Stable identifier for the profile                                     |
| `type`          | enum(ALES, ThermalDuration, F3J, F5J, F3L, F3K) | Yes      | —       | Discipline type                                                       |
| `version`       | int                                             | Yes      | —       | Rules profile version                                                 |
| `name`          | string                                          | Yes      | —       | Human-readable name of the discipline                                 |
| `description`   | string                                          | No       | —       | Longer description of the discipline and its rules                    |
| `category`      | enum(duration, multiple, other)                 | Yes      | —       | Category of discipline for grouping and selection purposes            |
| `status`        | enum(drafted, published, superseded)            | Yes      | drafted | Lifecycle status of this profile version                              |
| `superseded_by` | string                                          | No       | —       | Type of profile that supersedes this version (when status=superseded) |
| `created_by`    | string                                          | Yes      | —       | Author account identifier who created this profile version            |
| `created_at`    | datetime                                        | Yes      | —       | Timestamp of profile creation                                         |
| `updated_by`    | string                                          | No       | —       | Account identifier who last modified this profile (drafts only)       |
| `updated_at`    | datetime                                        | No       | —       | Timestamp of last modification (drafts only)                          |

## Invariants and Constraints

- The combination (`type`, `version`) must be unique.
- `version` increments monotonically for each discipline type; earlier versions remain immutable.
- Field identifiers and meanings are immutable within a given rules version.
- F3L and F3K are representable but not implemented until their official rules are formally defined.
- At least one formula must be specified for the primary score.

## Lifecycle

Profiles follow a create-once, version-advance lifecycle:

```plaintext
Drafted -> Published -> (optional) superseded by new version
```

- Drafted profiles may be modified arbitrarily.
- Published profiles are immutable; only a new version may supersede.
- Superseded versions remain queryable for historical score reproduction.
- No deletion lifecycle; profiles are retained indefinitely.

## Privacy and Scope

- Shared across all contests using a given discipline and rules version.
- No per-contest privacy settings (public reference document).
- Readable by all clients; mutations by profile administrators only.

## Audit and Synchronization

- Profiles are mutated only by profile administrators via the service.
- Published profiles are immutable; no mutation idempotency concerns.
- A new version creates a new profile entity; old versions are unchanged.
- All profile transitions (Published, superseded) record profile type, version, author, and server timestamp.
