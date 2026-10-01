# DisciplineProfile

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Stores a versioned official scoring profile for a soaring discipline. Defines configuration fields, score-entry fields, validation, zero reasons, formulas, normalization, rounding, and calculation metadata.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** None

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | PK | Yes | — | Stable identifier for the profile |
| `type` | enum(ALES, ThermalDuration, F3J, F5J, F3L, F3K) | Yes | — | Discipline type |
| `version` | int | Yes | — | Rules profile version |
| `config_fields` | object[] | Yes | [] | Allowed top-level configuration fields (name, type, required, range, default) |
| `score_entry_fields` | object[] | Yes | [] | Per-heat score-entry fields (name, type, required, range, units) |
| `validation_rules` | object[] | No | [] | Validation constraints for configuration and score entry |
| `zero_reasons` | enum[] | Yes | [] | Permitted codes for manual zero results (e.g. CRASH, DNF, LATE, OVERWEIGHT, NO_SHOW, TIME_LIMIT) |
| `formulas` | object[] | Yes | [] | Score and penalty formulas |
| `normalization_rules` | object[] | No | [] | Group scoring and normalization (matrix algorithm) |
| `rounding_rules` | object[] | Yes | [] | Per-field rounding or truncation rules (precision, direction) |
| `calculation_metadata` | object | Yes | {} | Metadata describing calculation steps (intermediate, final, penalties) |

## Invariants and Constraints
- The combination (`type`, `version`) must be unique.
- `version` increments monotonically for each discipline type; earlier versions remain immutable.
- Field identifiers and meanings are immutable within a given rules version.
- F3L and F3K are representable but not implemented until their official rules are formally defined.
- At least one formula must be specified for the primary score.

## Lifecycle
Profiles follow a create-once, version-advance lifecycle:
```
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