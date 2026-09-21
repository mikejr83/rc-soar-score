# Ticket 008 — Normalized Scoring: Retired Pilot in Group Maximum

- **Category:** Scoring Engine
- **Priority:** Low
- **Status:** Open

## Context

In normalized group scoring, a retired pilot receives a zero score. It is unclear whether that zero participates in the group maximum used for normalization.

## Questions

1. When a pilot retires mid-group, does their zero score count toward the group maximum used for normalization?
2. If all pilots in a group retire, what is the group maximum (all zeros)?
3. How is a retired pilot displayed on the public site — as 0, as "retired", or both?

## Decisions Needed

- Whether retired zeros participate in the group-max calculation.
- Display treatment of retired scores.

## Sources

- `plan/architecture-requirements/data/scores-and-results.md`
