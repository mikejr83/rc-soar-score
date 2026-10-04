# DisciplineValidation

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** Defines a validation constraint that relates two or more score-entry fields for a discipline variant. Enables the application to enforce cross-field rules at score entry time.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** DisciplineProfile  
**Child entities:** None

## Fields/Properties

| Field                   | Type                   | Required | Default | Description                                                                                 |
| ----------------------- | ---------------------- | -------- | ------- | ------------------------------------------------------------------------------------------- |
| `id`                    | PK                     | Yes      | —       | Stable identifier for the validation constraint                                             |
| `discipline_profile_id` | FK → DisciplineProfile | Yes      | —       | Discipline profile this validation belongs to                                               |
| `field_keys`            | json                   | Yes      | —       | JSON-encoded array of field key strings that the validation applies to (at least 2)         |
| `constraint_type`       | string                 | Yes      | —       | Type of validation (e.g., 'required_if', 'mutually_exclusive', 'less_than', 'greater_than') |
| `description`           | string                 | No       | —       | Explanation of the constraint for developers and administrators                             |
| `applies_to`            | json                   | No       | —       | JSON-encoded target values and field names specific to this constraint                      |
| `message`               | string                 | No       | —       | User-facing error message shown when validation fails                                       |
| `display_order`         | int                    | No       | 0       | Sort order for application of validations                                                   |
| `created_at`            | datetime               | Yes      | —       | Timestamp of validation definition creation                                                 |

## Invariants and Constraints

- The combination (`discipline_profile_id`, `field_keys`, `constraint_type`) must be unique.
- `field_keys` must contain at least two elements.
- All field keys referenced must exist in the discipline's score fields for the same version.
- Published profiles cannot modify existing validations; only a new version may.

## Lifecycle

Validations follow the profile version lifecycle:

```plaintext
Drafted → Published → (optional) superseded by new version
```

- Validations in published versions are immutable.
- New versions can add, remove, or change validation rules.

## Privacy and Scope

- Shared across all contests using the profile version.
- Read-only for all clients; mutations by profile administrators only.

## Audit and Synchronization

- All modifications create audit records with validation ID, value changes, author, and timestamp.
- Published versions create new validation rows in the new version; old rows unchanged.
