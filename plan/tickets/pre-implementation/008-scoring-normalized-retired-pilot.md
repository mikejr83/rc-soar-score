# Ticket 008 — Normalized Scoring: Retired Pilot in Group Maximum

- **Category:** Scoring Engine
- **Priority:** Low
- **Status:** ready

## Context

In normalized group scoring, a retired pilot receives a zero score (a retirement overlay evaluates unflown rounds `R ≥ retired_at_round` as zero with a `Retired` status, per `data/README.md`). It was unclear whether that zero participates in the group maximum used for normalization.

The normalization formula is `pilot raw score / highest raw score in the group × 1000` (F5J doc; ALES "Normalized"). `discipline-scoring.md` pipeline rule 4 states normalization "is based only on the **eligible pilots**," and shared-behavior rule 5 requires that an all-zero group normalizes to zero without dividing by zero. The open question was which pilots are "eligible" when one or more have retired.

## Questions

1. When a pilot retires mid-group, does their zero score count toward the group maximum used for normalization? — **Resolved: No. Retired pilots are excluded entirely from normalization (Decision 1). See Decisions.**
2. If all pilots in a group retire, what is the group maximum (all zeros)? — **Resolved: eligible set empty → all-zero group → every pilot 0, no division by zero (Decision 2). See Decisions.**
3. How is a retired pilot displayed on the public site — as `0`, as "retired", or both? — **Resolved: show `0` in the score column plus a separate retired status marker/tooltip (Decision 3). See Decisions.**

## Decisions Needed

- Whether retired zeros participate in the group-max calculation. — **Decided (Decision 1).**
- All-retired group behavior. — **Covered by Decision 1 + all-zeros guard (Decision 2).**
- Display treatment of retired scores. — **Decided (Decision 3).**

## Decisions

- **Decision 1 (Q1): Retired pilots are excluded entirely from the normalized group score.** The group maximum is computed over **eligible (non-retired) pilots only** — i.e., pilots whose round score is not `Retired`. A retired pilot:
  - is **not** counted in the group maximum (its 0 can never be the max), and
  - is **not** normalized; its round score stays `0` with the `Retired` reason/status flag retained.
  - Rationale: this matches `discipline-scoring.md` rule 4 ("normalization is based only on the eligible pilots") and `data/README.md` (retirement is an overlay that evaluates unflown rounds as zero _without_ materializing dummy records). Excluding retired pilots keeps normalization meaningful to the pilots who actually flew the round and avoids a retired pilot's 0 dragging a group's max down.
  - Formula restated: `max` = highest raw score among **non-retired** pilots in the group; each **non-retired** pilot's normalized score = `raw / max × 1000`; retired pilots retain `0` (`Retired`).

- **Decision 2 (Q2): All-retired (no eligible pilots) group.** When every pilot in a group is retired (no non-retired pilots), the eligible set is empty → the group is treated as an **all-zero group**: every pilot's normalized group score is `0` and the engine must **not** divide by zero. This is the degenerate case of Decision 1 combined with the existing all-zeros guard (`discipline-scoring.md` rule 5: "If every pilot in a group has a zero raw score, the normalized group score must be zero and must not divide by zero"). No separate special-casing beyond "eligible set empty → all zeros" is required.

- **Decision 3 (Q3): Public display of retired scores.** A retired pilot's round score is displayed as **`0` in the numeric score column**, accompanied by a **separate retired status marker/tooltip** (e.g., a superscript, icon, or hover tooltip reading "Retired") so the column remains numeric/machine-friendly while retired-ness stays visible. The `Retired` status/reason flag drives this marker. This is a presentation-only concern; it does not affect the stored value or the calculation.

## Acceptance criteria

- In a `Normalized` group, the group maximum is computed over **non-retired** pilots only; a retired pilot's 0 is never the max and the retired pilot is not normalized (its score stays `0` with a `Retired` status/reason flag).
- A group where **all pilots are retired** produces `0` for every pilot with no division by zero / no NaN (degenerate all-zero group).
- A group where some pilots are retired and some have non-zero raw scores normalizes the non-retired pilots against the non-retired max; retired pilots do not affect other pilots' normalized values.
- A retired pilot's round score is stored as `0` with the `Retired` status/reason flag, and is displayed on the public site as **`0` in the score column plus a separate retired status marker/tooltip** (Decision 3).
- Golden calculation fixtures include: (a) a group with one retired pilot among scoring pilots; (b) an all-retired group; (c) a group where the would-be max is a retired pilot (only possible in the all-retired / all-zeros case). The service and offline calculation library pass the same fixtures.

## Sources

- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/architecture-requirements/data/README.md` (retirement overlay; pipeline)
- `plan/architecture-requirements/discipline-scoring.md` (rules 4, 5)
- `plan/business-requirements/disciplines/f5j.md` (normalization formula; all-zero group)
- `plan/business-requirements/disciplines/ales.md` ("Normalized" mode)
- `plan/ui/participant-scoring/participant-scoring.md` (retired participants' read-only view)
