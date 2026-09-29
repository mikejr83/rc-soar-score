# Ticket 025 — Matrix: Adopt GliderScore Research Recommendations

- **Category:** Matrix / Draw
- **Priority:** High
- **Status:** ready
- **Decision:** Adopt the full construct-then-improve approach from the GliderScore research: greedy construction → conflict-directed local search over all rounds, fixed 300k-iteration budget, best-of-5 seeds (winning seed stored on the revision), lane co-optimization retained, and a linear never-met-pair penalty (w_never = 5). The algorithm is version `1.0.0`.

## Context

The `research/gliderscore-draw/README.md` contains measured, concrete recommendations that would change the draw engine's core algorithm. The plan has not yet adopted or rejected them.

## Recommendations Under Consideration

1. **Construct-then-improve:** Greedy construction followed by conflict-directed local search over all rounds, instead of pure simulated annealing.
2. **Size-scaled iteration budget:** 300k+ iterations for 480–882 placements (the current spec uses 30k, which the research found insufficient).
3. **Best-of-several-seeds:** Run 5 seeds, keep the best, store the winning seed for reproducibility.
4. **Penalize never-met pairs:** Add an explicit weight or lexicographic objective for pairs that never fly together.
5. **Keep lane co-optimization:** Continue optimizing lanes within the annealer rather than post-hoc assignment.

## Decisions

1. **Draw engine (Q1): Full adopt of construct-then-improve (Recommendation #1 + #2 + #3 + #5).** The pure simulated annealer in `matrix-draw.md` §4 is replaced. The new engine is: (a) greedy construction of a valid draw, (b) conflict-directed local search over all rounds, starting cool, with a size-scaled iteration budget, (c) best-of-several-seeds with the winning seed stored on the matrix revision, and (d) lane co-optimization retained. Recommendation #1 is measured best on all three benchmark contests (MAD −7.8% at 30 pilots, −3.3% at 63) and beats the spec SA as written. The remaining recommendations (#2 budget, #3 seeds, #4 never-met penalty) still require specific decisions — see Questions 2–5.
2. **Iteration budget (Q2): Fixed 300,000 iterations** for the local-search phase. This matches the value validated in the research (§5.2: "300k iterations for 480–882 placements was enough to match or beat GliderScore; 30k was not"). The budget is not scaled with problem size. Rationale: the three benchmark contests (23×6=138, 30×16=480, 63×14=882 placements) all use 300k successfully; practical RC soaring contests rarely exceed ~100 pilots / 20 rounds, and no larger configurations were measured. If a future contest size is found to need more iterations, the budget can be revisited as a new `algorithmVersion` bump.
3. **Seed strategy (Q3): Run 5 seeds, keep the best, store the winning seed.** The engine runs the full construct-then-improve algorithm with 5 independently generated random seeds. The matrix revision's `randomSeed` field stores the single 32-bit seed that produced the winning (lowest-cost) matrix. Reproducibility is preserved per §4.1: re-running the engine with that seed and identical inputs reproduces the exact same matrix on all platforms. This matches the research recommendation (§5.3: "Run several seeds and keep the best, storing the winning seed on the matrix revision") and the measured benefit (best-of-5 improves median MAD by ~5% vs. a single seed; per-seed spread is 4–13%).
4. **Never-met-pair penalty (Q4): Add a linear penalty term.** The cost function is extended to:
   `J = Σ(c(pᵢ,pⱼ) − μ)² + w_never · |{(pᵢ,pⱼ) : c(pᵢ,pⱼ) = 0}| + w_lane · J_lane`
   where `w_never` is a fixed weight (initial value: 5). Each never-met pair adds `w_never` to the total cost, making them significant relative to per-pair deviation terms. Rationale: the research (§4 finding 4) shows the quadratic objective under-weights never-met pairs (a never-met pair at 63 pilots costs ≈ 6.9 vs. a 6-meet pair at ≈ 11.4), so the optimizer trades never-met pairs for fewer heavy repeats. A linear count penalty directly addresses the "I never flew against X" complaint. The weight `w_never = 5` is an initial value (the research marks this recommendation as *untested*); it can be tuned in a follow-up `algorithmVersion` bump if the fairness report shows it is too weak or too strong.
5. **Algorithm version (Q5): `algorithmVersion = 1.0.0`.** The algorithm has not yet been implemented in code. The construct-then-improve approach with the extended cost function (including `w_never`), fixed 300k iteration budget, 5-seed strategy, and lane co-optimization is the first and only implementation. It is version `1.0.0`. The reproducibility guarantee (§4.1) applies: running the engine with identical inputs (P, R, G, teams, prior history, and seed) and `algorithmVersion = 1.0.0` produces the exact same matrix on all platforms. Future changes to the algorithm (e.g. tuning `w_never`, changing the iteration budget, or modifying the search strategy) will bump the version and will not affect existing revisions drawn under `1.0.0`.

## Questions

1. ~~Does the plan adopt the full construct-then-improve approach, keep the current SA, or adopt a subset?~~ — **Resolved: full adopt (Decision 1).**
2. ~~If adopting, what is the iteration budget and how is it scaled with problem size?~~ — **Resolved: fixed 300,000 iterations, not scaled (Decision 2).**
3. ~~How many seeds are run, and is the winning seed stored on the matrix revision?~~ — **Resolved: 5 seeds, keep best, store winning seed (Decision 3).**
4. ~~Is the never-met-pair penalty added to the cost function, and what weight?~~ — **Resolved: linear penalty term, w_never = 5 (Decision 4).**
5. ~~How does this change affect the existing `algorithmVersion` tag and reproducibility guarantees?~~ — **Resolved: `1.0.0`, first implementation (Decision 5).**

## Decisions Needed

- (All resolved — see Decisions.)

## Acceptance criteria

- The draw engine uses a two-phase algorithm: (1) a greedy construction phase that produces a valid draw satisfying all hard constraints (team protection, balanced group sizes, lane exclusivity), and (2) a conflict-directed local search phase that operates over all rounds and iteratively improves the cost function. The pure simulated annealer from `matrix-draw.md` §4 is replaced.
- The local search phase uses a fixed iteration budget of 300,000 iterations.
- The engine runs the algorithm with 5 independent random seeds and keeps the best result. The matrix revision's `randomSeed` field stores the winning seed, preserving §4.1 reproducibility guarantees.
- Lane assignments are co-optimized within the local search phase, not assigned post-hoc.
- The cost function includes a linear penalty term `w_never · (count of never-met pairs)` with `w_never = 5`, in addition to the existing quadratic matchup and lane terms.
- The `algorithmVersion` tag is set to `1.0.0`. The reproducibility guarantee holds: identical inputs (pilots, rounds, groups, teams, prior history, seed) and algorithm version produce the identical matrix on all platforms.

## Sources

- `research/gliderscore-draw/README.md` (§5 Recommendations, §6 Questions)
- `plan/architecture-requirements/matrix-draw.md` (§3–§4)
