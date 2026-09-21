# Ticket 004 — Configuration Override Scope

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** ready
- **Decision:** An override is a set of per-field deviations at the **contest level only** — no round- or group-level overrides — stored in the contest's revisioned configuration revision and computed as shared profile + overrides. Per-round behavior is derived, not configured. Q3 (inter-level conflict) is vacuous by construction; concurrency is ticket 016. Q4 (does an override force a new calculation revision when values don't change) is deferred to ticket 010.
- **Depends on:** ticket 010 (calc-affecting vs. presentational settings; invalidation scope), ticket 016 (config-edit concurrency), ticket 003 (matrix revision for draw-affecting config changes).

## Context

`disciplines-and-configuration.md` says "an override is linked to the official profile and never mutates the shared profile." An override is a set of per-field deviations from a discipline's shared official profile — it is *never* a new discipline definition. The effective configuration for a contest is computed as: shared profile (rules version) + the contest's explicit overrides, stored in a revisioned contest configuration revision. The unresolved questions are the granularity/scope of an override, how it interacts with per-round behavior, and whether/when it triggers recalculation.

## Questions

1. What is the granularity of a configuration override — per-contest, per-round, or per-discipline-setting? — **Resolved: per-field deviations at the contest level only (see Decisions).**
2. Can a contest override just one setting (e.g., height-penalty rate) while inheriting all others from the shared profile? — **Yes by construction; see Q1.**
3. How are conflicting overrides resolved if multiple apply (e.g., a contest-level and a round-level override for the same setting)? — **N/A: with only one override level there is no inter-level conflict. Intra-contest conflicts are a single per-field value (last write wins), governed by ticket 016 for concurrency.**
4. Does an override create a new calculation revision even if it doesn't change any score values? — **Deferred to ticket 010 (recalculation invalidation scope); see Decisions.**

## Decisions Needed

- Override scope model (which levels, how they compose, how they are stored).
- Whether and how overrides trigger recalculation.

## Decisions

- **Override level / scope (Q1):** An override is a set of **per-field deviations at the contest level only**. There is no round-level or group-level override. The effective configuration for the contest is computed as **shared profile (rules version) + the contest's explicit per-field overrides**, and this effective config is what a round's scored group uses. Per-round behavior is **derived, not configured**: e.g. "seeded from round N+1" is derived from `PreliminaryManOnManRounds` by the draw engine, not stored as a per-round override.
- **Storage:** Overrides live in the **revisioned contest configuration revision** (`contestId`, discipline id, rules version, and the explicit overrides blob/map). Each override entry stores the field identifier it deviates and the contest-specific value. The shared profile is never mutated.
- **Single setting (Q2):** Yes. Overriding any single setting (e.g. F5J height-penalty rate) is simply one entry in the overrides map; all other fields inherit from the shared profile. Overriding nothing = the contest uses the profile verbatim.
- **Conflict resolution (Q3):** With exactly one override level there is **no inter-level conflict**. Within the contest config, each field has exactly one override value, so the only "conflict" is concurrent editing — which is governed by **ticket 016** (config-contention concurrency). This ticket defines no level-precedence rules.
- **Recalculation trigger (Q4):** **Deferred to ticket 010.** This ticket defines the *storage* model for overrides; the question of *which* settings are calculation-affecting, and whether a value-unchanging override still bumps the calculation revision, is owned by ticket 010. The only contract 004 fixes here: a change to the contest configuration (including an override) produces a **new configuration revision**; whether that also forces a new calculation revision is ticket 010's call.
- **Relationship to matrix (per ticket 003):** A configuration change that affects the draw (draw mode, groups per round, team protection, lane mode, `PreliminaryManOnManRounds`) requires a **new matrix revision**; a re-draw produces a new revision covering the (re)generated rounds and past rounds stay in their original revision. A configuration change that affects only scoring (e.g. group-score mode, rounding, dropped-round policy, F5J height penalty) does **not** create a matrix revision — it affects calculations only (again per ticket 010 for the invalidation scope).

## Acceptance criteria

- An override is stored as a per-field deviation within the contest's revisioned configuration revision; it references the field identifier and the contest-specific value, and never mutates the shared discipline profile.
- Overriding any subset of fields (one or many) is supported; fields not overridden inherit from the shared profile (rules version). No override entries = profile used verbatim.
- There is no round-level or group-level override. Per-round behavior (e.g. when seeded drawing begins) is derived by the engine from a contest-level field (e.g. `PreliminaryManOnManRounds`), not stored as a separate per-round override.
- A change to the contest configuration (including adding/changing an override) always creates a new configuration revision.
- The acceptance criteria for *which* settings are calculation-affecting and whether a value-unchanging override bumps the calculation revision are owned by ticket 010 and are not asserted here.
- A draw-affecting configuration change requires a new matrix revision (per ticket 003); a scoring-only change does not.

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md` (override linked to profile, never mutates shared profile; calculation-affecting change creates a new calc revision)
- `plan/architecture-requirements/data/contest.md` (revisioned contest configuration; lifecycle mutability rules)
- `plan/business-requirements/contest-configuration.md` (deviation = contest override, not a new discipline definition; scoring/draw option fields)
- `plan/architecture-requirements/data/scores-and-results.md` (calc metadata: config revision, rules version, calculation version stored per derived result)
- `plan/tickets/pre-implementation/010-scoring-recalculation-invalidation-scope.md` (owns: which settings are calculation-affecting vs. presentational; invalidation scope)
- `plan/tickets/pre-implementation/016-sync-config-contention.md` (owns: concurrency model for concurrent config edits)
- `plan/tickets/pre-implementation/003-data-matrix-revision-granularity.md` (owns: how a draw-affecting config change maps to a new matrix revision)
