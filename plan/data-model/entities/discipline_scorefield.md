# DisciplineScoreField

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** Defines a score-entry field for a discipline variant. Each row specifies the schema, constraints, and zero-reason semantics for one field that score recorders enter during a round.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** DisciplineProfile  
**Child entities:** None

## Fields/Properties

| Field                   | Type                                                      | Required | Default | Description                                                                                                                                                                                                                                                        |
| ----------------------- | --------------------------------------------------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`                    | PK                                                        | Yes      | —       | Stable identifier for the score field                                                                                                                                                                                                                              |
| `discipline_profile_id` | FK → DisciplineProfile                                    | Yes      | —       | Discipline profile this field belongs to                                                                                                                                                                                                                           |
| `field_key`             | string                                                    | Yes      | —       | Unique identifier within the profile version that clients and calculators use                                                                                                                                                                                      |
| `field_type`            | enum(string, int, float, bool, enum, date, time, landing) | Yes      | —       | Data type of the field value. `landing` types generate their options from the LandingResults of the contest's landing table (`ContestConfigurationRevision.landing_table_id`); the `options` property is empty. The stored value is the selected LandingResult id. |
| `name`                  | string                                                    | Yes      | —       | Human-readable label for UI display                                                                                                                                                                                                                                |
| `description`           | string                                                    | No       | —       | Longer explanation of what this field represents                                                                                                                                                                                                                   |
| `field_kind`            | enum(input, status_flag, derived)                         | Yes      | input   | Whether the field is a value the scorer enters, a status flag, or a value the calculation derives. Derived fields are never entered                                                                                                                                |
| `unit`                  | string                                                    | No       | —       | Unit of the canonical stored value, for example `seconds` or `meters`. Display formats such as `MM:ss` are not the stored value                                                                                                                                    |
| `precision`             | int                                                       | No       | —       | Number of decimal places kept in the canonical value                                                                                                                                                                                                               |
| `required`              | bool                                                      | No       | false   | If the score entry must include this field                                                                                                                                                                                                                         |
| `default_value`         | json                                                      | No       | —       | JSON-encoded default value (string, number, bool, date, time, etc.)                                                                                                                                                                                                |
| `options`               | json                                                      | No       | —       | JSON-encoded array of allowed values for enum fields                                                                                                                                                                                                               |
| `validation`            | json                                                      | No       | —       | JSON-encoded validation constraints (min, max, pattern, etc.)                                                                                                                                                                                                      |
| `display_order`         | int                                                       | No       | 0       | Sort order for UI rendering of fields                                                                                                                                                                                                                              |
| `is_zero_reason`        | bool                                                      | No       | false   | If the field represents a zero-score condition                                                                                                                                                                                                                     |
| `zero_reason_code`      | string                                                    | No       | —       | The `rule_key` of the matching `rule_type: zero` DisciplineRule in the same profile (when is_zero_reason=true)                                                                                                                                                     |
| `created_at`            | datetime                                                  | Yes      | —       | Timestamp of field definition creation                                                                                                                                                                                                                             |

## Invariants and Constraints

- The combination (`discipline_profile_id`, and `field_key`) must be unique.
- `options` may only be present when `field_type` is `enum`.
- `default_value` must be valid JSON matching the schema implied by `field_type`.
- If `is_zero_reason` is true, `zero_reason_code` must be present and must equal the `rule_key` of a zero DisciplineRule in the same profile.
- A `derived` field is not accepted in a score submission.
- Published profiles cannot modify existing score fields; only a new version may.

## Lifecycle

Score fields follow the profile version lifecycle:

```plaintext
Drafted → Published → (optional) superseded by new version
```

- Fields in published versions are immutable.
- New versions can add, remove, or change field keys.

## Privacy and Scope

- Shared across all contests using the profile version.
- Read-only for all clients; mutations by profile administrators only.

## Audit and Synchronization

- All modifications create audit records with field key, value change, author, and timestamp.
- Published versions create new field rows in the new version; old rows unchanged.
