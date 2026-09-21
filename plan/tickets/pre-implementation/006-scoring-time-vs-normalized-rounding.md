# Ticket 006 — Time vs. Normalized Group-Score Rounding

- **Category:** Scoring Engine
- **Priority:** Medium
- **Status:** Open

## Context

In `Time` group-score mode, the relationship between per-round rounding and the final contest total is ambiguous.

## Questions

1. In `Time` mode, is each pilot's group score rounded to the configured precision before summing into the contest total, or are contest totals computed at full precision and rounded only at the end?
2. Does the same question apply to `Normalized` mode (round each normalized group score, or sum at full precision)?
3. How does the dropped-round selection interact with rounding — is the drop applied to rounded or unrounded values?
4. Is the rounding/truncation setting applied at the group level, the contest level, or both?

## Decisions Needed

- Rounding point in the pipeline for each group-score mode.
- Whether drop selection operates on rounded or unrounded values.

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/architecture-requirements/discipline-scoring.md`
