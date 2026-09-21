# Ticket 010 — Recalculation Invalidation Scope

- **Category:** Scoring Engine
- **Priority:** Medium
- **Status:** Open

## Context

"Any calculation-affecting change invalidates derived results and creates a new calculation revision." The boundary between calculation-affecting and presentational changes is not defined.

## Questions

1. Which configuration settings are calculation-affecting vs. presentational?
2. Does a change to decimal precision alone trigger a full recalc, or only when the rounded values would differ?
3. Does a change to the landing-bonus table trigger a recalc for already-scored rounds, or only future rounds?
4. When a recalculation is triggered, which derived records are invalidated — all, or only those downstream of the changed setting?

## Decisions Needed

- A clear list of calculation-affecting settings.
- The invalidation scope (full vs. targeted).

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/architecture-requirements/data/scores-and-results.md`
