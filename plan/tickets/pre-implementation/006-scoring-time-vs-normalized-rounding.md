# Ticket 006 — Time vs. Normalized Group-Score Rounding

- **Category:** Scoring Engine
- **Priority:** Medium
- **Status:** ready

## Context

In `Time` group-score mode, the relationship between per-round rounding and the final contest total is ambiguous. `discipline-scoring.md` pipeline rule 5 ("apply the configured final group-score rounding or truncation once, after normalization and other group-score arithmetic. No intermediate raw, penalty, or normalization value may be rounded or truncated") reads as a **group-stage** rounding, but the ALES business doc (`ales.md`, "Truncating and Rounding") says rounding applies **only to the final group score, never at an intermediate step**, and the F3J/F5J docs label the setting "Total Score — rounded/truncated to N decimal places." These conflict.

## Questions

1. In `Time` mode, is each pilot's group score rounded to the configured precision before summing into the contest total, or are contest totals computed at full precision and rounded only at the end? — **Resolved: full precision; rounded only at the end (final total). See Decisions.**
2. Does the same question apply to `Normalized` mode (round each normalized group score, or sum at full precision)? — **Resolved: same as `Time` — full precision; rounded only at the end. See Decisions.**
3. How does the dropped-round selection interact with rounding — is the drop applied to rounded or unrounded values? — **Resolved: unrounded (full precision). See Decisions.**
4. Is the rounding/truncation setting applied at the group level, the contest level, or both? — **Resolved: contest level (final total) only. See Decisions.**
5. (Follow-up from Q1) Under full-precision pipeline, how is the **team total** derived — does each pilot's contest total get rounded/truncated per the contest configuration **before** summing into the team total, or is the team total computed at full precision and rounded once? — **Resolved: round/truncate each pilot total first, then sum. See Decisions.**

## Decisions Needed

- Rounding point in the pipeline for each group-score mode.
- Whether drop selection operates on rounded or unrounded values.
- How the team total is derived and rounded relative to pilot totals.

## Decisions

- **Rounding point (Q1, Q2):** The configured precision (rounding **or** truncation, 0–3 decimal places) is applied **only to the final contest total**. The entire pipeline up to that point — raw score, group score (`Time` or `Normalized`), dropped-round selection, and cumulative penalties — is computed at **full precision**, with **no intermediate rounding or truncation**. (The team total is derived from the already-rounded pilot totals — see Q5.) This matches `ales.md` ("Truncating and Rounding": rounding/truncation never happens at an intermediate step; it applies to the final group/total score) and the "Total Score — rounded/truncated to 1 decimal place" labels in `f3j.md`/`f5j.md`.
  - Consequence for stored values: the **group score is stored at full precision** (the ALES worked example's "Rounded to 0 decimal places → 1035" is a *display* rounding of that full-precision value, not a value fed downstream). The only value the setting actually truncates/rounds is the final contest total.
  - **Conflict to resolve in the plan:** `discipline-scoring.md` pipeline rule 5 as currently worded ("apply the … rounding … once, after normalization and other group-score arithmetic") describes a **group-stage** rounding and must be reworded to: the configured rounding/truncation is applied **once, to the final contest total**, and no intermediate raw, penalty, normalization, or group-score value may be rounded or truncated.
- **Level (Q4):** The precision setting is a single **contest-level** setting (rounding/truncation + decimal count). It is **not** applied at the group level and there is no separate per-group precision. There is exactly one application point (the final total).
- **Dropped-round interaction (Q3):** Because the pipeline is full-precision (decision above), the dropped-round selection operates on **unrounded, full-precision** group/round scores. There is no upstream rounding that could alter which round is dropped. Dropped-round selection is unaffected by the configured precision setting; it always selects on the exact full-precision values (subject to the non-droppable-zero rule owned by ticket 009).
- **Team total (Q5):** The team total is the **sum of the top N pilots' contest totals after each pilot total has already been rounded/truncated** per the contest configuration (team size N, ordered highest to lowest, per pipeline rule 8). Each pilot's rounded/truncated contest total is the canonical value fed into the team total; the team total is **not** recomputed from full-precision values and then rounded. Consequently the published team total **equals** the sum of the published (rounded/truncated) pilot totals, and no further rounding/truncation is applied to the team total itself (it is exactly the sum of the already-rounded pilot totals).

## Acceptance criteria

- The scoring engine computes raw score, group score (`Time`, `Normalized`, or `Raw`), dropped-round selection, and cumulative penalties **at full precision** with no intermediate rounding or truncation; the per-pilot contest total is the only value the configured rounding/truncation is applied to, and the team total is derived from those already-rounded pilot totals (see the team-total criterion below).
- The configured rounding/truncation setting (0–3 decimals, round or truncate) is applied **exactly once**, to the **final contest total** per pilot.
- Group scores are stored at full precision; any rounding of a stored group score in a report/public view is a display-only rounding of that stored value, not an input to a downstream calculation.
- Dropped-round selection is performed on full-precision group/round scores and is independent of the configured precision setting.
- The team total is the sum of the top N pilots' contest totals **after** each pilot total has been rounded/truncated per the contest configuration; the team total is exactly the sum of those already-rounded pilot totals and is itself not independently rounded/truncated.
- `discipline-scoring.md` pipeline rule 5 is reworded so the single rounding/truncation application is described as applying to the **final contest total** (not "after normalization / group-score arithmetic"), removing the conflict with `ales.md` and the F3J/F5J "Total Score" labels.
- Golden fixtures for a multi-round, dropped-round scenario (both `Time` and `Normalized` modes) confirm: (a) each pilot's final contest total equals the configured rounding/truncation of that pilot's full-precision total; and (b) the team total exactly equals the sum of the top-N pilots' already-rounded/truncated contest totals.
- The same golden fixtures pass identically in the service and in the offline calculation library.

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/architecture-requirements/discipline-scoring.md`
