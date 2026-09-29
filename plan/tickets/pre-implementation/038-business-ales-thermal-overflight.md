# Ticket 038 — Business: ALES/Thermal Target-Time Over-Flight

- **Category:** Business Rules
- **Priority:** Medium
- **Status:** ready
- **Decision:** Over-flight of the target time is scored by continuous deduction — `pts/sec × target − pts/sec × (time − target)`, floored at 0 — not by a time cap and not as a F5J-style late landing. The recorded (entered) time is never capped at the target.
- **Decision:** The one-minute boundary: a pilot who lands at or before one minute past the target time scores normally (with deduction) and earns the landing bonus. Over-flight strictly **greater than** one minute past the target produces zero flight and landing values, recorded as the `OVER_FLIGHT` zero reason selected by the operator — the application never derives the zero from the entered time alone.
- **Decision:** The over-flight rule is identical for ALES and Thermal. The only differences between the two profiles are the default group-score mode (ALEs `Time`, Thermal `Normalized`) and the motor-restart zero reason, which exists in ALES only.

## Context

`discipline-scoring.md` requires that ALES and Thermal tests cover "target-time over-flight, the one-minute over-flight boundary." The ticket's original premise was that "the exact behavior is not specified in the business requirements" — that is incorrect: `ales.md` and `thermal.md` specify the over-flight formula, the one-minute zero condition, the flag-based entry, the validation behavior, and the UI behavior. The only genuine ambiguity was the landing-bonus treatment of an in-window over-flighted flight, because F5J's contrasting rule ("late landing forfeits the bonus") is a strong attractor for readers.

The source documents establish:

- **Continuous deduction, not a cap.** At or under target: `pts/sec × time`. Over target: `pts/sec × target − pts/sec × (time − target)`, result floored at 0. The ALES worked example is decisive: at a 480 s target, 1 pt/s, 483 s flown → raw 477 (not capped at 480).
- **The one-minute window.** A pilot who lands at or before one minute past target scores normally (with deduction). Over-flight **greater than** one minute past target (plus out-of-bounds; plus motor restart in ALES) produces zero flight and landing values, stored as the mutually exclusive `OVER_FLIGHT` zero reason (ticket 012). Exactly one minute past is scorable; the zero condition is strictly greater than one minute.
- **The application judges nothing from the entered time.** The operator selects the "Over-Flight of Greater Than One Minute" flag. The entry screen accepts a time greater than the target, but a time **more than** one minute past the target should be met with an error directing the operator to select the flag, which disables and zeroes all other fields.
- **Contrast with F5J.** F5J caps recorded time at the working time and forfeits the landing bonus on a late landing. ALES/Thermal do **not** cap time and do **not** forfeit the landing bonus for an in-window over-flight.
- **Rounding.** Per ticket 006, the pipeline is full precision; the only rounding/truncation is applied once, to the final contest total. The ALES example's "Rounded to 0 decimal places → 1035" is display rounding of the full-precision group score, not a value fed downstream. (`discipline-scoring.md` rule 5 as worded conflicts with this and must be reworded per ticket 006.)

## Questions

1. In ALES/Thermal, what happens when a pilot overflies the target time — is the time capped at the target (like F5J's working time), or is there a penalty? — **Resolved:** continuous deduction of `pts/sec` per second over target, floored at 0; the recorded time is not capped (ales.md/thermal.md computational rules; ALES worked example).
2. What is the one-minute over-flight boundary — can the pilot land up to 1 minute after the target time expires? — **Resolved:** yes. Landings at or before one minute past target score normally; strictly more than one minute past target is the zero condition (`OVER_FLIGHT` reason, ticket 012), recorded by operator flag selection, never derived from the entered time alone.
3. If the pilot lands within the one-minute boundary, is the time capped at the target or at the actual landing time? — **Resolved:** neither — the actual time enters the deduction formula: `pts/sec × target − pts/sec × (actual − target)`, floored at 0.
4. Does the landing bonus apply if the pilot lands within the one-minute boundary? — **Resolved (product owner, 2026-09-21): yes** — an in-window over-flight earns the landing bonus normally, confirmed for ALES and Thermal.
5. How does the over-flight rule differ between ALES and Thermal? — **Resolved (confirmed by product owner): it does not.** The over-flight rule is identical in both profiles; the only differences are the default group-score mode and the ALES-only motor-restart zero reason.

## Decisions Needed

- The over-flight rule for ALES and Thermal. — **Decided:** continuous deduction floored at 0, no cap; >1 minute past target zeroes flight and landing via the operator-selected flag (Decision 1).
- The one-minute boundary behavior and its effect on landing bonus. — **Decided:** in-window over-flight is not a zero condition and earns the landing bonus (Decision 2).
- ALES vs. Thermal differences. — **Decided:** none in the over-flight rule (Decision 3).

## Decisions

- **Decision 1 (Q1/Q2/Q3): Continuous deduction; one-minute forfeit boundary; flag-based.** The ALES and Thermal raw flight score is `pts/sec × time` at or under target; `pts/sec × target − pts/sec × (time − target)` over target; the result is never negative. An in-window over-flight (e.g. 483 s against a 480 s target at 1 pt/s) scores 477 — the entered time is never capped at the target. The zero condition is over-flight **strictly greater than one minute** past the target (landings exactly one minute past are scorable); when it occurs, flight and landing both score zero and the reason is `OVER_FLIGHT` (`zeroReason` on a `ZERO` outcome, ticket 012). Per the business spec, the application does **not** judge over-flight from the entered time: the entry screen accepts a time greater than the target, and a time more than one minute past the target is met with an error directing the operator to select the "Over-Flight of Greater Than One Minute" flag, which disables and zeroes all other fields. Server-side, the profile rejects a submission whose time exceeds one minute past target without the `OVER_FLIGHT` flag (validation rules, `discipline-scoring.md`), rather than auto-deriving or repairing the score.
- **Decision 2 (Q4): An in-window over-flight earns the landing bonus — confirmed by the product owner for ALES and Thermal.** An in-window over-flight is not a zero condition and is not a F5J-style "late landing." The flight time scores by the target-time deduction formula (floored at 0) and pilot's landing is scored from the selected landing table, added according to the contest's group-score mode (ALEs default `Time`: flight time normalized to 1000 first, then the landing bonus added; Thermal default `Normalized`: flight time plus landing bonus, then normalized to 1000). Only over-flight greater than one minute past target, out-of-bounds landing, and (ALEs only) motor restart produce zero flight and landing values. Each discipline handles the over-flight condition per its own spec; F5J's "late landing forfeits the bonus" behavior does not carry over to ALES/Thermal.
- **Decision 3 (Q5): ALES and Thermal share the identical over-flight rule.** The two profiles differ only in: (a) default group-score mode — ALES `Time`, Thermal `Normalized` (changing either is a contest override with a director warning, per their discipline docs), and (b) the motor-restart zero reason, which is present in ALES (mutually exclusive with `OUT_OF_BOUNDS` and `OVER_FLIGHT`) and absent from Thermal (mutually exclusive only between `OUT_OF_BOUNDS` and `OVER_FLIGHT`). Over-flight zeros carry no non-droppable property in either profile (that exists only for F5J motor restarts under the `Non-Droppable 0` option, tickets 009/012).

## Acceptance Criteria

- Both ALES and Thermal compute the raw flight score with the target-time formula: `pts/sec × time` at or under target; `pts/sec × target − pts/sec × (time − target)` over target; the result is never negative. An over-flighted in-window flight (e.g. 483 s against a 480 s target at 1 pt/s) scores 477 — it is not capped at the target.
- `OVER_FLIGHT` is a zero condition with `zeroReason = OVER_FLIGHT` on a `ZERO` outcome (ticket 012). It is mutually exclusive with `OUT_OF_BOUNDS` and `MOTOR_RESTART` in ALES and with `OUT_OF_BOUNDS` in Thermal. Selecting the flag zeroes and disables all other score fields (time, landing).
- The zero boundary is strictly "greater than one minute past target": exactly target + 60 s (at the profile's configured time precision) is scorable by the deduction formula; target + 60 s plus the smallest representable time unit is not valid as a time entry and requires the `OVER_FLIGHT` flag.
- An in-window over-flight earns the landing bonus per the configured group-score mode: ALES `Time` — flight raw points normalized to 1000 first, landing bonus added afterward; Thermal `Normalized` — flight points plus landing bonus, then normalized to 1000 (Decisions 1–2).
- The entry screen accepts a time greater than the target; a time more than one minute past the target produces an error directing the operator to select the "Over-Flight of Greater Than One Minute" flag. The application never derives the over-flight zero automatically from the entered time alone.
- Server-side validation rejects a submission whose time exceeds one minute past target without the `OVER_FLIGHT` flag; it does not auto-derive or silently repair the zero (decisions 1, consistent with `discipline-scoring.md` validation rules).
- The pipeline computes these scores at full precision with no intermediate rounding; the only rounding/truncation is applied once to the final contest total per contest configuration (ticket 006). Group scores are stored at full precision.
- Golden fixtures (per `discipline-scoring.md` verification requirement 3) include: (a) an in-window over-flight (e.g. 483 s / 480 s target, both `Time` and `Normalized` modes) verifying the deduction and landing-bonus ordering; (b) the one-minute boundary — exactly one minute past target scores normally, and just over one minute produces an `OVER_FLIGHT` zero via the flag; (c) a group where all pilots over-fly in-window in `Time` mode, verifying landing bonus is added after normalization; (d) a group containing an `OVER_FLIGHT` zero among normal scores (normalization treats it as raw 0) and an all-zero group (group score 0, no divide-by-zero); (e) a rejected submission (time > target + 60 s without the flag) that does not mutate official data.
- The same golden fixtures pass identically in the service and in the offline calculation library.

## Sources

- `plan/architecture-requirements/discipline-scoring.md` (initial discipline profiles ALES/Thermal; shared duration-scoring behavior; validation and authority; verification requirement 3)
- `plan/business-requirements/disciplines/ales.md` (computational rules; scoring components; validation; scoring formula; examples)
- `plan/business-requirements/disciplines/thermal.md` (computational rules; scoring components; scoring formula)
- Related tickets: 006 (Time vs. Normalized rounding — full-precision pipeline, rounding only on the final contest total), 009/012 (zero reasons and droppability; `zeroReason` on `ZERO` outcome), 010 (recalculation invalidation scope), 036 (out-of-bounds flag pattern), 037 (zero-reason flag pattern), 007 (F3J late landing — the contrasting "late landing" concept that does not apply here)
