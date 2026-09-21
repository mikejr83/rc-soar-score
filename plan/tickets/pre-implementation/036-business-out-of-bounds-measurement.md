# Ticket 036 — Business: Out-of-Bounds Landing Distance Measurement

- **Category:** Business Rules
- **Priority:** Low
- **Status:** ready
- **Decision:** 75 m is an informational, discipline-tracked constant (default for the duration profiles) that the app **displays** to the user; it is never stored on a score nor computed against. Out-of-bounds is recorded as an operator-indicated flag, not a measured distance.
- **Decision:** Either the pilot (self-entry) or the contest director (entering on the pilot's behalf) can set the out-of-bounds flag on the score-entry form. The app records the boolean only.
- **Decision:** The out-of-bounds flag follows the standard score lifecycle. It is editable in draft/submitted state by whoever may edit the score (pilot or director) and locked once the score is official/locked. Toggling it re-normalizes the group exactly like any other raw-score change (ticket 010); no special handling.

## Context

The F5J spec defines an out-of-bounds landing as "greater than 75 m from the pilot's landing marker." The measurement method and configurability are not specified.

Cross-checked against the broader plan: every duration profile (F5J, F3J, thermal, ALES) defines out-of-bounds as "greater than 75 m from the pilot's landing marker," and all of them treat it as a user **indicator** — selecting it disables and zeroes the other score fields. Ticket 007 already models this as a boolean `outOfBounds` flag with **no distance stored**; ticket 012 makes it a `zeroReason` (`OUT_OF_BOUNDS`) on a `ZERO` outcome. So the application never measures or stores a landing distance — this ticket's "measurement" is really about the rule the human applies when judging a landing, and how the app surfaces it.

## Questions

1. Is the 75 m measured from the landing marker (a specific point) or from the center of the landing zone? — **Resolved: the app does not measure it. The 75 m rule is applied by the human judging the landing against "the pilot's landing marker" (the discipline wording is retained verbatim as the displayed rule).**
2. Is it a straight-line (as-the-crow-flies) distance or along a defined path? — **Resolved: not applicable to the app; no distance is computed. Left to the operator's field judgment, with the displayed rule as stated.**
3. Is the 75 m distance configurable per contest, or a fixed rule? — **Resolved: fixed, informational, discipline-tracked constant (default 75 m). Displayed to the user; not stored on a score and not computed against (Decision 1).**
4. How is the distance determined in practice — by the timer, the pilot, or a measurement tool? — **Resolved: by the pilot or the contest director, whichever is entering the score; the app only records the boolean flag (Decision 2).**
5. Is the out-of-bounds determination made before or after score entry (i.e., can it be changed after the score is entered)? — **Resolved: it follows the standard score lifecycle — editable in draft/submitted state, locked when official/locked, with standard re-normalization on change (Decision 3).**

## Decisions Needed

- The measurement method for out-of-bounds landings. — **Decided: none in the app; operator-indicated flag (Decision 1).**
- Whether the distance threshold is configurable. — **Decided: fixed informational constant, displayed only (Decision 1).**
- Who may set the flag. — **Decided: pilot or director, per score entry (Decision 2).**
- Post-entry editability and recalculation. — **Decided: standard score lifecycle, standard re-normalization (Decision 3).**

## Decisions

- **Decision 1 (Q1/Q2/Q3): No in-app measurement; informational constant.** The application does **not** compute, validate, or store a landing distance. The "greater than 75 m from the pilot's landing marker" rule is treated as an **informational, discipline-tracked constant** (default 75 m for the duration profiles) that the score-entry UI **displays** to the end user as guidance for judging a landing. It is a fixed profile constant (not a per-contest configurable value). Selecting the flag zeroes and disables the other score fields and stores OutcomeStatus `ZERO` with `zeroReason = OUT_OF_BOUNDS` (ticket 012); no distance field is added to the score model.
- **Decision 2 (Q4): Source of truth is the score entrant.** Either the **pilot** (self-entry) or the **contest director** (entering on the pilot's behalf) determines and sets the out-of-bounds flag on the score-entry form. The app records the boolean only; it is not derived from any timer, telemetry, or measurement tool.
- **Decision 3 (Q5): Standard lifecycle and recalculation.** The out-of-bounds flag is treated exactly like the other discipline scoring elements with respect to the score's lifecycle: editable in draft/submitted state by whoever may edit that score (pilot or director, per Decision 2), and locked once the score is official/locked. Changing it flips the raw score to/from 0 and triggers standard group re-normalization (ticket 010) — no special-case handling beyond what the engine already does for any raw-score change.

## Acceptance criteria

- The score model stores out-of-bounds as a boolean `outOfBounds` flag / `zeroReason = OUT_OF_BOUNDS` on a `ZERO` outcome; **no** landing-distance field is stored on a score. (Decision 1, consistent with tickets 007 and 012.)
- The score-entry UI displays the 75 m out-of-bounds rule as informational text for the user; it does not ask for a distance input and does not compute or validate a distance. (Decision 1)
- The 75 m value is a fixed discipline constant (default 75 m) surfaced from the discipline profile; it is not a per-contest configurable field. (Decision 1)
- Selecting out-of-bounds zeroes and disables the other score fields (time, altitude/height, landing bonus, late landing) and produces a `ZERO` raw score, per the profile and ticket 007/012 behavior. It remains mutually exclusive with late landing and "no altitude recorded," and may co-occur with motor restart (existing profile rules).
- Both pilot self-entry and director entry expose the out-of-bounds toggle (subject to the helper/role rules in tickets 017/031). (Decision 2)
- The flag is editable only while the score is in draft/submitted state and is immutable once official/locked. Toggling it re-normalizes the group exactly as any other raw-score change does (ticket 010). (Decision 3)
- Golden fixtures include: (a) a group with one `OUT_OF_BOUNDS` zero among normal scores — verifying normalization treats it as raw 0; (b) a group where all pilots are `OUT_OF_BOUNDS` — verifying all-normalize-to-0 with no divide-by-zero; (c) a draft→submitted edit that toggles `outOfBounds` on/off — verifying re-normalization matches the ticket-010 recalculation behavior.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Out of Bounds Landing; Scoring Components; Zero Score Clarifications)
- `plan/business-requirements/disciplines/f3j.md`, `thermal.md`, `ales.md` (Out of Bounds Landing — same rule)
- `plan/architecture-requirements/discipline-scoring.md` (rule 3: OOB records profile reason, zeroes flight/landing; rule 4: reason flags; rule 5: all-zero group)
- Related tickets: 007 (F3J late-landing penalty; boolean `outOfBounds` flag, no distance stored), 012 (score outcome status; `zeroReason`), 010 (recalculation invalidation scope), 017 (helper role), 031 (pilot score-review workflow)
