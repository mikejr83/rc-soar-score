# Ticket 037 — Business: F5J "No Altitude Recorded" — Purpose and Drop Behavior

- **Category:** Business Rules
- **Priority:** Low
- **Status:** ready
- **Decision (partial):** "No Altitude Recorded" is a reporting/statistics-only zero-reason flag (Decision 1). It is **droppable** — it behaves exactly like a plain zero and never participates in the F5J `Non-Droppable 0` (motor-restart) logic (Decision 2). A round recorded this way can later be corrected to a real score via the normal score-edit/recalculation path (Decision 3). Display is `0` plus a "No Altitude Recorded" reason marker (ticket 012, Decision 3).

## Context

The F5J "No Altitude Recorded" option produces a zero score but is tracked separately from a regular zero. Its purpose and interaction with the drop logic are not specified.

Settled elsewhere (not re-decided here):
- It is `OutcomeStatus = ZERO` with a `zeroReason` flag, never a distinct status (ticket 012, Decision 4).
- Display: `0` in the numeric column plus a distinct reason marker (ticket 012, Decision 3).
- Normalization: 0 raw score; an all-zero group normalizes to 0 with no division by zero (F5J doc "Zero Score Clarifications"; `discipline-scoring.md` rule 5).
- Entry-screen behavior: selecting it unselects/disables late landing, motor restart, and out-of-bounds, and no other values may be entered (F5J doc).

## Questions

1. What is the purpose of the "No Altitude Recorded" categorization — for post-contest analysis, protest handling, or something else? — **Resolved: reporting/statistics only (Decision 1).**
2. Is a "No Altitude Recorded" zero droppable or non-droppable in the drop logic? — **Resolved: droppable, behaves like any plain zero (Decision 2).**
3. Does it interact with the "Non-Droppable 0" motor-restart option (i.e., is it treated as a motor-restart zero for drop purposes)? — **Resolved: no — it is never treated as a motor-restart zero; it does not participate in the non-droppable logic (Decision 2, corollary).**
4. How is it displayed on the public site — as "0" or "No Altitude Recorded"? — **Resolved: `0` plus a distinct "No Altitude Recorded" reason marker/tooltip, per ticket 012 Decision 3.**
5. Can a pilot who selected "No Altitude Recorded" later have their altitude recorded and their score corrected? — **Resolved: yes, via the normal score-edit/correction path (Decision 3).**

## Decisions Needed

- The purpose of the "No Altitude Recorded" category. — **Decided (Decision 1).**
- Its behavior in the drop logic and display. — **Decided (Decision 2); display per ticket 012.**

## Decisions

- **Decision 1 (Q1): Reporting/statistics only.** The `NO_ALTITUDE_RECORDED` reason exists so a post-contest report can distinguish an instrument-failure zero from genuine forfeit zeros (motor restart, out-of-bounds, over-fly) and from a genuine `0`. It carries no other behavioral effect beyond the standard zero path: the round scores 0, and it behaves as a normal zero for everything not decided below (normalization, display, entry-screen exclusivity). No protest/correction workflow and no fairness-report feed is attached to it.

- **Decision 2 (Q2, Q3): Droppable — behaves exactly like any plain zero.** In the dropped-round selection (pipeline step 7), a `NO_ALTITUDE_RECORDED` round is treated as a raw score of `0` and **is** a candidate to be dropped, exactly like any other plain zero. The reason flag is stored for reporting only and **never** influences dropability.
  - Corollary (Q3): it is **not** treated as a motor-restart zero for drop purposes. The F5J `Non-Droppable 0` rule protects **only** motor-restart zeros; a `NO_ALTITUDE_RECORDED` zero never participates in the non-droppable logic and never blocks a drop. Under `Non-Droppable 0`, the drop still selects the lowest round and may select a `NO_ALTITUDE_RECORDED` zero.
  - Distinction from ticket 009: ticket 009's non-droppable protection applies to the `MOTOR_RESTART` reason only. `NO_ALTITUDE_RECORDED` has no such protection, so the all-zeros drop logic (ticket 009, Decision 1) is unaffected — the only reason that can make a zero non-droppable is `MOTOR_RESTART`.

- **Decision 3 (Q5): Correctable via the normal score-edit path.** A round recorded as `NO_ALTITUDE_RECORDED` can later be converted to a real computed score through the **standard score-edit/correction flow** (director or authorized role edits the round: clears the No Altitude Recorded flag and enters time, altitude, and landing as a normal score). The system then recalculates and records a new score revision, preserving the original submission, superseded values, and the audit trail per `discipline-scoring.md` recalculation rules. **No special mechanism or dedicated "re-score" operation is introduced** — the existing recalculation/revision model handles it.

## Acceptance criteria

- A "No Altitude Recorded" F5J round is stored with `OutcomeStatus = ZERO` and `zeroReason = NO_ALTITUDE_RECORDED`; it is **not** a distinct status value. (Consistent with ticket 012, Decision 4.)
- The round's raw score is `0`. No time, altitude, or landing component is recorded for it, and selecting it on the entry screen unselects/disables late landing, motor restart, and out-of-bounds and prevents entry of other values (F5J doc).
- **Normalization:** it participates as raw score `0` in the group maximum; a group where all pilots are zeros (including any `NO_ALTITUDE_RECORDED` zeros) normalizes to `0` with no division by zero (F5J doc "Zero Score Clarifications"; `discipline-scoring.md` rule 5). It is treated as eligible for normalization, not excluded.
- **Drop logic:** it is **droppable** and behaves exactly like any plain zero — the dropped-round selection treats it as raw score `0` and may drop it, regardless of the reason flag (Decision 2).
- **Non-droppable interaction:** it is **never** treated as a motor-restart zero and does **not** participate in the F5J `Non-Droppable 0` logic; the drop may select a `NO_ALTITUDE_RECORDED` zero. The only reason that can make a zero non-droppable is `MOTOR_RESTART` (Decision 2; ticket 009).
- **Display:** on the public site it shows `0` in the numeric score column plus a distinct "No Altitude Recorded" reason marker/tooltip (ticket 012, Decision 3). The marker wording is `"No Altitude Recorded"`.
- **Reporting:** the `NO_ALTITUDE_RECORDED` reason flag is stored and available so a post-contest report can distinguish instrument-failure zeros from motor-restart, out-of-bounds, over-fly forfeit zeros, and genuine `0`s (Decision 1).
- **Correction:** a round recorded as `NO_ALTITUDE_RECORDED` can be converted to a real computed score via the normal score-edit/correction flow (clear the flag, enter time/altitude/landing, recalculate). The system records a new score revision and preserves the original submission, superseded values, and audit trail; no special re-score mechanism is required (Decision 3; `discipline-scoring.md` recalculation rules).
- Golden calculation fixtures include: (a) an F5J group mixing computed scores with a `NO_ALTITUDE_RECORDED` zero (verifying it normalizes as 0 and is a drop candidate); (b) an all-zeros group containing a `NO_ALTITUDE_RECORDED` zero (normalizes to 0, no division by zero); (c) an F5J `Non-Droppable 0` case where the lowest round is a `NO_ALTITUDE_RECORDED` zero (the drop **does** select it, since only `MOTOR_RESTART` is protected). The service and offline calculation library pass the same fixtures.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (No Altitude Recorded)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rule 4)
