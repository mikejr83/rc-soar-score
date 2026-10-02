# DisciplineRule

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** Defines a scoring, penalty, conditional logic, or zero-score rule for a discipline variant. Captures the condition, effect, computational logic, and display/UX metadata in a single entity.

The `rule_type` enum determines what the rule does:

- `calc` - computation rule (e.g., calculate height penalty)
- `penalty` - penalty rule (e.g., time over target)
- `zero` - zero-score condition (e.g., out of bounds, motor restart)
- `interaction` - rule describing how other fields/conditions interact
- `other` - catch-all for rule types not covered above

For `rule_type: "zero"` rules, the entity includes display and UX metadata (`display_name`, `description`, `auto_score_zero`, `affects_other_fields`) so score-entry fields that represent zero conditions can reference a single source of truth.

**Identifier:** `id` (UUIDv7)  
**Parent entity:** DisciplineProfile  
**Child entities:** None

## Fields/Properties

| Field                   | Type                                          | Required | Default | Description                                                                          |
| ----------------------- | --------------------------------------------- | -------- | ------- | ------------------------------------------------------------------------------------ |
| `id`                    | PK                                            | Yes      | —       | Stable identifier for the rule                                                       |
| `discipline_profile_id` | FK → DisciplineProfile                        | Yes      | —       | Discipline profile this rule belongs to                                              |
| `rule_key`              | string                                        | Yes      | —       | Unique identifier within the profile version for this rule                           |
| `rule_type`             | enum(calc, penalty, zero, interaction, other) | Yes      | —       | What the rule does (scoring, penalty, zero condition, field interactions)            |
| `condition`             | string                                        | No       | —       | Rule condition expression (e.g., "flight_time_over_target" for overflight penalties) |
| `effect`                | string                                        | No       | —       | Outcome when condition is met (e.g., "score = 0" or "30 point penalty")              |
| `applies_to`            | json                                          | No       | —       | JSON array of field keys or formula keys the rule interacts with or depends on       |
| `depends_on`            | json                                          | No       | []      | JSON array of rule keys that must be evaluated before this rule                      |
| `display_name`          | string                                        | No       | —       | Screen label shown to users (required when rule_type is zero)                        |
| `description`           | string                                        | No       | —       | Longer explanation of the condition for documentation and administrator review       |
| `auto_score_zero`       | bool                                          | No       | true    | If setting this zero reason automatically scores the flight as 0                     |
| `affects_other_fields`  | json                                          | No       | []      | JSON array of field keys that become disabled or zeroed when this is selected        |
| `display_order`         | int                                           | No       | 0       | Sort order for evaluation of rules within a calculation chain                        |
| `created_at`            | datetime                                      | Yes      | —       | Timestamp of rule definition creation                                                |

## Invariants and Constraints

- The combination (`discipline_profile_id` and `rule_key`) must be unique.
- If `rule_type` is `zero`, `display_name` and `display_order` must be provided.
- `applies_to` must be valid JSON (JSON array).
- `depends_on` must be valid JSON (JSON array of rule keys).
- `affects_other_fields` must be valid JSON (JSON array).
- Published profiles cannot modify existing rules; only a new version may.

## Lifecycle

Rules follow the profile version lifecycle:

```plaintext
Drafted → Published → (optional) superseded by new version
```

- Rules in published versions are immutable.
- New versions can add, remove, or change rules.

## Privacy and Scope

- Shared across all contests using the profile version.
- Read-only for all clients; mutations by profile administrators only.

## Audit and Synchronization

- All modifications create audit records with rule ID, value changes, author, and timestamp.
- Published versions create new rule rows in the new version; old rows unchanged.
