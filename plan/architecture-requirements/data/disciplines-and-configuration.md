# Disciplines and Configuration

## Discipline profile

A discipline has a stable identifier and a versioned official scoring profile. A profile defines configuration fields, score-entry fields, validation, zero reasons, formulas, normalization, rounding, and calculation metadata. Field identifiers and meanings are immutable within a rules version.

The initial duration profiles are ALES, Thermal Duration, F3J, and F5J. F3L and F3K remain representable but are not implemented until their rules are defined.

## Contest configuration

A contest configuration revision stores the selected discipline identifier and rules version plus explicit overrides. It must include group-score mode (`Raw`, `Normalized`, or `Time`), final rounding/truncation and decimal precision, dropped-round policy, target or working time, points per second, landing table revision, and discipline-specific settings such as F5J height penalties and motor-restart mode.

An override is linked to the official profile and never mutates the shared profile. Any calculation-affecting change invalidates derived results and creates a new calculation revision.

## Landing tables

A landing table has a stable identifier, revision, input unit/meaning, and entries mapping a selected key such as distance to resolved points. A score stores both the selected key and resolved points plus the table revision used. Historical scores therefore remain reproducible if a table changes later.

## Derived configuration metadata

Store the calculation version, profile/rules version, configuration revision, and applicable matrix revision with every calculated result. The service, not a client, is authoritative for validation and calculation.
