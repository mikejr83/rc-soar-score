# Ticket 012 — Score Outcome Status: Not Entered, Explicit Zero, Retired

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** ready
- **Decision:** Separated lifecycle/status from outcome status. OutcomeStatus = `NOT_ENTERED`, `ZERO`, `RETIRED` (Decision 1). NOT_ENTERED = raw 0, droppable, normalizes as 0, displayed `0` + "no score entered" indicator (Decisions 2–3). F5J zero reasons are reason flags on `ZERO`, never a distinct status (Decision 4).

## Context

`scores-and-results.md` states that "missing, explicit zero, and retired outcomes remain distinguishable." The data model has no field representing this status yet.

The score placeholder "distinguishes `NotEntered`, draft, submitted, zero, retired, review, official, and locked presentation outcomes" — but that list conflates lifecycle/lock/review _state_ with the flight _outcome_. This ticket separates the two and defines the outcome dimension precisely.

## Questions

1. Is this an enum on the score record (`MISSING`, `ZERO`, `RETIRED`), or separate flags? — **Resolved: a dedicated OutcomeStatus enum; lifecycle/status is a separate field (Decision 1).**
2. Does each status have different behavior in the drop logic, normalization, and public display? — **Resolved: Decision 2 (drop) + Decision 3 (normalization/display). RETIRED per ticket 008.**
3. Is a "missing" score (pilot never flew) droppable, or does it count as a non-droppable zero? — **Resolved: it is a raw 0 and IS a drop candidate (Decision 2).**
4. How does the "No Altitude Recorded" F5J zero interact with this status — is it a `ZERO` with a reason flag, or a distinct status? — **Resolved: a `ZERO` with a `zeroReason` flag; never a distinct status (Decision 4).**

## Decisions Needed

- The outcome-status enum and its values. — **Decided (Decision 1).**
- Per-status behavior in drop logic, normalization, and display. — **Decided (Decisions 2–3).**
- F5J zero-reason interaction. — **Decided (Decision 4).**

## Decisions

- **Decision 1 (Q1): Two dimensions — a lifecycle/status field and an OutcomeStatus field.** The score carries an independent **OutcomeStatus** enum with exactly three values:
  - `NOT_ENTERED` — no flight outcome exists for this round (the "missing" outcome; the pilot never produced a score for the round).
  - `ZERO` — an explicit zero was entered/recorded (possibly with a zero _reason_: out-of-bounds, motor restart, no-altitude-recorded, etc.).
  - `RETIRED` — the round is unflown and counted as zero by the retirement overlay (no score attempt is materialized; see `data/README.md`).
    Lifecycle/`state` (draft, submitted, official, locked, review) is a **separate** field on the score placeholder and is not part of the outcome status. The engine's drop/normalization/display logic branches only on OutcomeStatus; reason flags are a further independent attribute of a `ZERO` (not a distinct status).

- **Decision 2 (Q2 — drop stage): `NOT_ENTERED` counts as a raw score of 0 and IS a candidate for being dropped.** A `NOT_ENTERED` round has no entered raw components; for the dropped-round selection (pipeline step 7) its raw score is treated as `0`, so it participates as a zero candidate alongside explicit `ZERO` rounds. The drop logic therefore does not special-case `NOT_ENTERED` — it drops the lowest raw score(s), which may be a `NOT_ENTERED` round. (Interaction with a `ZERO`'s _reason_ flag / non-droppable marking is governed by the discipline profile and tickets 009/037; the outcome status itself carries no dropability flag — see Decision 4 for how a profile expresses non-droppable.)

- **Decision 3 (Q2 — normalization + display): `NOT_ENTERED` normalizes as 0 and is displayed as `0` plus a distinct "no score entered" indicator.** For normalization (pipeline step 4) a `NOT_ENTERED` round is treated as raw score `0` and participates as an eligible pilot (it is NOT excluded from the group max, unlike `RETIRED`). On the public/participant site it is displayed as **`0` in the numeric score column**, accompanied by a **distinct "no score entered" indicator** (marker/tooltip). This indicator is explicitly separate from the `RETIRED` retired marker (ticket 008, Decision 3) and from any `ZERO` reason marker, so the three outcomes remain visually distinguishable while the column stays numeric/machine-friendly. Presentation-only; it does not affect stored values or calculation.

- **Decision 4 (Q4): F5J zero reasons are reason flags on a `ZERO` outcome, never a distinct status.** A forced-zero F5J reason — out-of-bounds landing, motor restart, or no-altitude-recorded — is stored as a **zero _reason_ flag/enum on a score whose OutcomeStatus is `ZERO`**. It is not a fourth OutcomeStatus value.
  - The _non-droppable_ property of a motor-restart zero (the F5J `Non-Droppable 0` option) is expressed as **profile-driven behavior keyed off the zero's reason + contest config**, not off the OutcomeStatus. The OutcomeStatus enum itself carries no droppability flag; the drop stage (Decision 2) reads the reason flag to decide whether a particular `ZERO` round is droppable (governed by `discipline-scoring.md` F5J rule 4 and tickets 009/037).
  - `NO_ALTITUDE_RECORDED` behaves identically to the other forced-zero reasons for status purposes (it is a `ZERO` with that reason). Its droppability/display specifics are decided in ticket 037 and do not add a status value.
  - This keeps OutcomeStatus exactly three-valued (Decision 1) and makes all F5J zeros structurally consistent: status = `ZERO`, plus a discriminant `zeroReason` (`OUT_OF_BOUNDS` | `MOTOR_RESTART` | `NO_ALTITUDE_RECORDED` | …) as an independent attribute.

## Acceptance criteria

- The score model carries two independent fields: a **lifecycle/status** field (draft, submitted, official, locked, review) and an **OutcomeStatus** field. OutcomeStatus is a three-valued enum: `NOT_ENTERED`, `ZERO`, `RETIRED`. (Decision 1)
- `RETIRED` is produced by the retirement overlay on rounds `R ≥ retired_at_round` with no materialized score attempt; its raw score is `0`. (Per `data/README.md` and ticket 008.)
- In the dropped-round selection (pipeline step 7), a `NOT_ENTERED` round is treated as raw score `0` and **is** a candidate to be dropped; a `ZERO` round with a profile-marked non-droppable reason (e.g. F5J motor restart under `Non-Droppable 0`) is excluded from drop selection per the discipline profile (tickets 009/037). The OutcomeStatus field itself carries no droppability flag. (Decision 2)
- In normalization (pipeline step 4), a `NOT_ENTERED` round participates as raw score `0` and is **not** excluded from the group max (unlike `RETIRED`, ticket 008). (Decision 3)
- Public/participant display: `NOT_ENTERED` → `0` in the numeric column plus a distinct "no score entered" indicator; `RETIRED` → `0` plus a retired marker (ticket 008); `ZERO` → `0` plus its reason marker. All three remain distinguishable; the numeric column stays machine-friendly. (Decision 3)
- Every F5J forced zero (out-of-bounds, motor restart, no-altitude-recorded) is stored with OutcomeStatus `ZERO` plus a `zeroReason` flag; no forced-zero reason introduces a new OutcomeStatus value. (Decision 4)
- Golden calculation fixtures include: (a) a group mixing entered scores, a `NOT_ENTERED` round, a `ZERO` round, and a `RETIRED` round — verifying normalization treats `NOT_ENTERED`/`ZERO` as 0 but excludes `RETIRED` from the group max; (b) a per-pilot drop scenario where the dropped round is `NOT_ENTERED`; (c) an F5J `Non-Droppable 0` case where the lowest round is a `ZERO` with reason `MOTOR_RESTART`. The service and any offline calculation library pass the same fixtures.

## Sources

- `plan/architecture-requirements/data/scores-and-results.md` (placeholder presentation outcomes; distinguishability)
- `plan/architecture-requirements/data/README.md` (retirement overlay; calculation pipeline)
- `plan/architecture-requirements/discipline-scoring.md` (pipeline steps 4/7; F5J rule 4 non-droppable zero)
- `plan/business-requirements/disciplines/f5j.md` (No Altitude Recorded; Motor Restart)
- Related tickets: 008 (retired in group max), 009 (non-droppable all-zeros), 037 (no-altitude-recorded purpose/drop/display)
