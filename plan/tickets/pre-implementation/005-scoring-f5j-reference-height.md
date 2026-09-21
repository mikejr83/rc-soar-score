# Ticket 005 — F5J Height Penalty: Reference Height Default and Scope

- **Category:** Scoring Engine
- **Priority:** High
- **Status:** Open

## Context

The F5J height penalty is two-tier: minor penalty (default 0.5 pts/m) below a reference height, major penalty (default 3 pts/m) above it. The minor and major per-meter rates have defaults, but the reference height itself has no stated default.

## Questions

1. What is the default reference height, and can it be configured per contest?
2. Is the reference height static for the whole contest, or can it vary per group/round (e.g., if the launch hill changes)?
3. Is the height penalty always applied (i.e., a pilot launching to 13 m gets 6.5 pts off), or is there a grace period below some altitude where no penalty applies?
4. How does the reference height interact with the "result cannot be negative" rule — is the floor applied before or after the penalty?

## Decisions Needed

- Default and configuration model for the reference height.
- Whether the penalty has a zero-penalty floor.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Launch Height Penalty, Computational Rules)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rules 2–3)
