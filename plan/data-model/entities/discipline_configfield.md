# DisciplineConfigField

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Defines a single configurable field for a discipline variant. Each row specifies the schema, constraints, and default value for one contest-scoped configuration setting.
**Identifier:** `id` (UUIDv7)
**Parent entity:** DisciplineProfile
**Child entities:** None

## Fields/Properties

| Field                   | Type                                          | Required | Default | Description                                                                                                                                                                             |
| ----------------------- | --------------------------------------------- | -------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                    | PK                                            | Yes      | —       | Stable identifier for the config field                                                                                                                                                  |
| `discipline_profile_id` | FK → DisciplineProfile                        | Yes      | —       | Discipline profile this field belongs to                                                                                                                                                |
| `field_key`             | string                                        | Yes      | —       | Unique identifier within the profile version that clients and calculators use                                                                                                           |
| `field_type`            | enum(string, int, float, bool, enum, landing) | Yes      | —       | Data type of the field value. `landing` types reference a linked `LandingTable` entity; the `options` property is empty for landing types and the link is specified in `default_value`. |
| `name`                  | string                                        | Yes      | —       | Human-readable label for UI display                                                                                                                                                     |
| `description`           | string                                        | No       | —       | Longer explanation of what this field controls                                                                                                                                          |
| `required`              | bool                                          | No       | false   | If the contest must set this field                                                                                                                                                      |
| `default_value`         | json                                          | No       | —       | JSON-encoded default value (string, number, bool, or enum value)                                                                                                                        |
| `options`               | json                                          | No       | —       | JSON-encoded array of allowed values for enum fields (each option may have value, label, etc.)                                                                                          |
| `validation`            | json                                          | No       | —       | JSON-encoded validation constraints (min, max, pattern, etc.)                                                                                                                           |
| `display_order`         | int                                           | No       | 0       | Sort order for UI rendering of fields                                                                                                                                                   |
| `created_at`            | datetime                                      | Yes      | —       | Timestamp of field definition creation                                                                                                                                                  |

## Invariants and Constraints

- The combination (`discipline_profile_id` and `field_key`) must be unique.
- `options` may only be present when `field_type` is `enum`.
- `default_value` must be valid JSON matching the schema implied by `field_type`.
- Published profiles cannot modify existing config fields; only a new version may.
- When `field_type` is set to `landing` the `default_value` should contain the uuid matching the `LandingTable` entity which will be used.

## Lifecycle

Config fields follow the profile version lifecycle:

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
