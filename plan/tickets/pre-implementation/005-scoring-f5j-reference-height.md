# Ticket 005 — F5J Height Penalty: Reference Height Default and Scope

- **Category:** Scoring Engine
- **Priority:** High
- **Status:** ready

## Context

The F5J height penalty is two-tier: minor penalty (default 0.5 pts/m) below a reference height, major penalty (default 3 pts/m) above it. The minor and major per-meter rates have defaults, and the reference height itself also has a default — **200 m**, the FAI F5J specification value used in the worked examples. A contest director may set a different reference height for their contest; that is recorded as a contest-level configuration **override** (per ticket 004), not a new discipline.

## Questions

1. What is the default reference height, and can it be configured per contest? — **Resolved: default 200 m; contest-level override (see Decisions).**
2. Is the reference height static for the whole contest, or can it vary per group/round (e.g., if the launch hill changes)? — **Resolved: static for the whole contest, frozen from `Running` (see Decisions).**
3. Is the height penalty always applied (i.e., a pilot launching to 13 m gets 6.5 pts off), or is there a grace period below some altitude where no penalty applies? — **Resolved: always applied, no grace period; minimum recorded altitude is 1 m (see Decisions).**
4. How does the reference height interact with the "result cannot be negative" rule — is the floor applied before or after the penalty? — **Resolved: floor the raw score at 0, after the penalty is subtracted (see Decisions).**

## Decisions Needed

- Default and configuration model for the reference height.
- Whether the penalty has a zero-penalty floor.

## Decisions

- **Default value (Q1a):** The profile default for the F5J reference launch height is **200 m** (whole meters), matching the FAI F5J specification and the worked examples in `f5j.md`. It is a _profile_ default, not a per-contest value.
- **Configuration model (Q1b):** The reference height is a **required field in the F5J discipline profile** (unit: meters, integer/whole meters, valid range ≥ 1). It is stored in the revisioned contest configuration. A contest that uses the default sets no override; a contest that needs a different value (e.g. a different launch hill) stores a single per-field override in its configuration revision, exactly per the ticket-004 model (shared profile + per-field contest override). The profile default (200 m) is never mutated.
- **Interaction with the two-tier formula:** With the default in place the calculation is fully specified — at/below reference, penalty = `altitude * minor`; above reference, penalty = `reference * minor + (altitude - reference) * major` (per `f5j.md` formula and `discipline-scoring.md` rule 3).
- **Scope / mutability:** Per ticket 004 the reference height is a **contest-level** value only — it cannot vary per round or per group within a single configuration revision. **Frozen from `Running`:** the reference height may be set/changed only before the contest reaches `Running`. Once `Running`, it is locked (consistent with `discipline-scoring.md` rule 96: discipline/scoring-rule changes prohibited once running). A mid-contest launch-hill change is therefore **not** handled by editing this config; it is handled by the director re-entering/adjusting the affected scores. It does not require a matrix revision (per ticket 004).
- **No grace period (Q3):** The penalty is applied to **every recorded meter**. There is no zero-penalty floor below some altitude. The minimum recordable launch altitude is **1 m** (0 m is not a valid recorded altitude). The first tier is therefore simply `altitude * minor` for `1 m ≤ altitude ≤ reference`, and `reference * minor + (altitude - reference) * major` above the reference. The only way a flight carries **no** height penalty is when it is zeroed for one of the zero-score reasons (out-of-bounds, no altitude recorded, motor restart) — in which case time, height, and landing are all recorded as 0 per the spec.
- **Negative floor (Q4):** The "result cannot be negative" rule is applied to the **raw score**, **after** the height penalty is subtracted. The raw score is `flight-time points + eligible landing bonus − height penalty`, floored at 0. I.e. `raw = max(0, timePoints + landingBonus - heightPenalty)`. The penalty is computed in full; only the final raw result is clamped. This matches `f5j.md` ("The lowest score a pilot can receive for their raw score is 0") and `discipline-scoring.md` rule 2 ("The result cannot be negative").

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Launch Height Penalty, Computational Rules)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rules 2–3)
- `plan/tickets/pre-implementation/004-data-config-override-scope.md` (owns: contest-level override model; F5J height penalty is a scoring-only change, no matrix revision)
- `plan/architecture-requirements/data/disciplines-and-configuration.md` (contest configuration revision stores F5J height penalties as discipline-specific settings)

## Acceptance criteria

- The F5J profile declares a `reference launch height` field with unit meters, type whole-number/integer, valid range ≥ 1 m, and a **default of 200 m**.
- A contest using the default stores no override for this field; a contest using a different value stores exactly one per-field override in its revisioned configuration revision (per ticket 004), and the shared profile default (200 m) is never mutated.
- The reference height is a contest-level value only: it cannot vary per round or per group within a single configuration revision.
- The reference height may only be set or changed **before** the contest reaches `Running`; once `Running` it is locked.
- The height penalty is computed as:
  - `altitude * minor` when `1 m ≤ altitude ≤ reference`;
  - `reference * minor + (altitude - reference) * major` when `altitude > reference`.
- There is **no** zero-penalty grace period: every recorded meter contributes to the penalty. The only way a flight carries no height penalty is when it is zeroed for a zero-score reason (out-of-bounds / no altitude recorded / motor restart), in which case time, height, and landing are all recorded as 0.
- A recorded launch altitude of 0 m is invalid; the minimum recordable altitude is 1 m (unless the flight is zeroed for a zero-score reason, where altitude is recorded as 0).
- The raw score is `max(0, flightTimePoints + eligibleLandingBonus - heightPenalty)`; the negative floor is applied to the raw score **after** the penalty is subtracted.
- The penalty is always applied for flights that have a valid (≥ 1 m) recorded altitude; the penalty itself is computed in full and never clamped — only the final raw score is floored at 0.
- Late landings preserve the flight-time points and the height penalty but forfeit the landing bonus (no landing bonus added), so the floor applies to `timePoints - heightPenalty`.
