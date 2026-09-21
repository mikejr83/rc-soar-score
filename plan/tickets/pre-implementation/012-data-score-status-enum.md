# Ticket 012 — Score Status: Missing, Explicit Zero, Retired

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Open

## Context

`scores-and-results.md` states that "missing, explicit zero, and retired outcomes remain distinguishable." The data model has no field representing this status yet.

## Questions

1. Is this an enum on the score record (`MISSING`, `ZERO`, `RETIRED`), or separate flags?
2. Does each status have different behavior in the drop logic, normalization, and public display?
3. Is a "missing" score (pilot never flew) droppable, or does it count as a non-droppable zero?
4. How does the "No Altitude Recorded" F5J zero interact with this status — is it a `ZERO` with a reason flag, or a distinct status?

## Decisions Needed

- The status enum and its values.
- Per-status behavior in drop logic, normalization, and display.

## Sources

- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/business-requirements/disciplines/f5j.md` (No Altitude Recorded)
