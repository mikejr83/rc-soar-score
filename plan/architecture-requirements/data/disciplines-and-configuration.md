# Disciplines and Configuration

## Discipline profile

A discipline has a stable identifier and a versioned official scoring profile. A profile defines configuration fields, score-entry fields, validation, formulas, and rules. Field identifiers and meanings are immutable within a rules version.

The initial duration profiles are ALES, Thermal Duration, F3J, and F5J. F3L and F3K remain representable but are not implemented until their rules are defined.

## Contest configuration

A contest configuration revision stores the selected discipline identifier and rules version plus explicit overrides. It must include group-score mode (`Raw`, `Normalized`, or `Time`), final rounding/truncation and decimal precision, dropped-round policy, target or working time, points per second, landing table, and discipline-specific settings such as F5J height penalties and motor-restart mode.

An override is linked to the official profile and never mutates the shared profile. Any calculation-affecting change invalidates derived results and creates a new calculation revision.

## Landing tables

A landing table has a stable identifier, input unit/meaning, and entries mapping a selected key such as distance or points to resolved points. A table is not tied to a discipline. Each discipline profile names the table it ships with as its default, directors can create their own tables, and the contest configuration selects the table a contest uses, which may be any table the director can see. A table never changes after it is created, so a change means a new table. A score stores the selected entry's identifier, which fixes the key, the resolved points, and the table, so historical scores remain reproducible. A contest's landing table cannot be changed once a landing score has been entered.

## Discipline rules, validation, and zero conditions

A discipline's scoring rules are encoded in a single `DiciplineRule` entity per rule. The `rule_type` enum determines what the rule does:

- `calc` - computation rule (e.g., calculate height penalty)
- `penalty` - penalty rule (e.g., time over target)
- `zero` - zero-score condition (e.g., out of bounds, motor restart)
- `interaction` - rule describing how other fields/conditions interact
- `other` - catch-all for rule types not covered above

Validation constraints (e.g., "time cannot exceed working time", "mutually exclusive zero conditions") are stored in a separate `DisciplineValidation` entity, decoupling field validation from scoring rule computation.

Score-entry fields that represent zero-score conditions (e.g., `motor_restart`, `out_of_bounds`) reference the corresponding `rule_key` of the matching `rule_type: zero` rule. This single rule entity carries both the computational logic (`condition`, `effect`) and the display/UX metadata (`display_name`, `description`, `affects_other_fields`) the scorer needs.

## Derived configuration metadata

Store the calculation version, profile/rules version, configuration revision, and applicable matrix revision with every calculated result. The service, not a client, is authoritative for validation and calculation.
