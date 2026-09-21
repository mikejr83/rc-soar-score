# Ticket 025 — Matrix: Adopt GliderScore Research Recommendations

- **Category:** Matrix / Draw
- **Priority:** High
- **Status:** Open

## Context

The `research/glidercore-draw/README.md` contains measured, concrete recommendations that would change the draw engine's core algorithm. The plan has not yet adopted or rejected them.

## Recommendations Under Consideration

1. **Construct-then-improve:** Greedy construction followed by conflict-directed local search over all rounds, instead of pure simulated annealing.
2. **Size-scaled iteration budget:** 300k+ iterations for 480–882 placements (the current spec uses 30k, which the research found insufficient).
3. **Best-of-several-seeds:** Run 5 seeds, keep the best, store the winning seed for reproducibility.
4. **Penalize never-met pairs:** Add an explicit weight or lexicographic objective for pairs that never fly together.
5. **Keep lane co-optimization:** Continue optimizing lanes within the annealer rather than post-hoc assignment.

## Questions

1. Does the plan adopt the full construct-then-improve approach, keep the current SA, or adopt a subset?
2. If adopting, what is the iteration budget and how is it scaled with problem size?
3. How many seeds are run, and is the winning seed stored on the matrix revision?
4. Is the never-met-pair penalty added to the cost function, and what weight?
5. How does this change affect the existing `algorithmVersion` tag and reproducibility guarantees?

## Decisions Needed

- The draw engine algorithm (SA vs. construct-then-improve).
- Iteration budget, seed strategy, and cost function weights.

## Sources

- `research/glidercore-draw/README.md` (§5 Recommendations, §6 Questions)
- `plan/architecture-requirements/matrix-draw.md` (§3–§4)
