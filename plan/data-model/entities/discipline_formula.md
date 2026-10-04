# DisciplineFormula

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** Defines a score or penalty calculation formula for a discipline variant. Each row represents one step in the scoring calculation, from raw score computation to final normalization.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** DisciplineProfile  
**Child entities:** None

## Fields/Properties

| Field                   | Type                                                | Required | Default | Description                                                                              |
| ----------------------- | --------------------------------------------------- | -------- | ------- | ---------------------------------------------------------------------------------------- |
| `id`                    | PK                                                  | Yes      | —       | Stable identifier for the formula                                                        |
| `discipline_profile_id` | FK → DisciplineProfile                              | Yes      | —       | Discipline profile this formula belongs to                                               |
| `formula_key`           | string                                              | Yes      | —       | Unique identifier within the profile version that clients and calculators use            |
| `description`           | string                                              | No       | —       | Explanation of what this formula computes for documentation purposes                     |
| `formula_text`          | string                                              | Yes      | —       | Expression text as a string (e.g., "flightPoints + landingBonus - heightPenalty")        |
| `formula_type`          | enum(raw, intermediate, penalty, final, normalized) | Yes      | —       | What stage and purpose this formula serves in the calculation chain                      |
| `inputs`                | json                                                | Yes      | —       | JSON object mapping input name to the field key or constant that provides the value      |
| `outputs`               | json                                                | No       | —       | JSON object mapping output name to the target field or variable that receives the result |
| `depends_on`            | json                                                | No       | []      | JSON array of formula keys that must be computed before this formula can be evaluated    |
| `is_primary`            | bool                                                | No       | false   | Indicates the primary scoring formula (only one formula may be marked primary)           |
| `display_order`         | int                                                 | No       | 0       | Sort order for formulas within a calculation chain; lower processed first                |
| `created_at`            | datetime                                            | Yes      | —       | Timestamp of formula definition creation                                                 |

## Invariants and Constraints

- The combination (`discipline_profile_id`, and `formula_key`) must be unique.
- Exactly one formula per profile version may have `is_primary` set to true.
- `inputs` must be valid JSON. All input references must be resolvable to score fields or constants within the profile or calculation context.
- `depends_on` must be valid JSON. Cycles in dependencies are not allowed.
- Published profiles cannot modify existing formulas; only a new version may.

## Lifecycle

Formulas follow the profile version lifecycle:

```plaintext
Drafted → Published → (optional) superseded by new version
```

- Formulas in published versions are immutable.
- New versions can add, remove, or change formulas.

## Privacy and Scope

- Shared across all contests using the profile version.
- Read-only for all clients; mutations by profile administrators only.

## Audit and Synchronization

- All modifications create audit records with formula ID, expression change, author, and timestamp.
- Published versions create new formula rows in the new version; old rows unchanged.
