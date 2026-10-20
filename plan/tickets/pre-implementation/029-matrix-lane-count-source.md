# Ticket 029 — Matrix: Lane Count (Configured vs. Derived)

- **Category:** Matrix / Draw
- **Priority:** Low
- **Status:** Decided
- **Decision:** ~~Lane count is derived from the pilot and group counts (L = ceil(N / G)), not configured. (2026-10-04)~~ ~~**Superseded 2026-10-07:** lane count is a contest option `lane_count` (default: the largest group size, used only with `lane_mode` `Random`), because fields have a fixed number of pegs. See [matrix-draw.md](../../architecture-requirements/matrix-draw.md) §3.1.~~ **Superseded 2026-10-20:** the lane count is derived again, as the largest group size of the scheduled round's original draw; `lane_count` is retired and issue #256 is closed as not planned. The reference application derives the lane count from the group size without it ever being a problem, a mismatch is visible when ⌈N/G⌉ exceeds the launch positions and self-corrects by redrawing the matrix, and a field with more pegs than the largest group size is not believed to occur.

## Context

It is unclear whether the number of lanes is a contest configuration set by the director, or derived from the number of groups.

## Questions

1. ~~Is the lane count a contest configuration, or derived from ⌈N / G⌉?~~ **Resolved: derived.** The draw defines the lane count as L = ⌈N / G⌉ ([matrix-draw.md](../../architecture-requirements/matrix-draw.md) §3.1). The only lane-related contest option is `lane_mode` (`None` or `Random`). With `Random`, an assignment's lane is between 1 and the largest group size of its round; with `None` the lane is null ([matrix_assignment.md](../../data-model/entities/matrix_assignment.md)).
2. ~~If configured, can the director set a lane count greater than the number of groups?~~ **Not applicable.** There is no configured lane count.
3. ~~If derived, what happens when the number of pilots changes mid-contest?~~ **Resolved:** existing assignments keep their stored lanes, and a retired pilot is an overlay that does not redraw the matrix. A later draw or redraw derives L from the pilots participating at that time.
4. ~~Does the lane count affect the feasibility invariant or the draw algorithm?~~ **Resolved:** it enters the draw only through the lane-balance penalty in the draw objective. It is not an input of its own and does not change the feasibility rules.

## Decisions

- Lane count is derived from the pilot and group counts, not configured.
- No schema impact.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§3.1, `L = ⌈N/G⌉`)
- `research/glidercore-draw/README.md` (§6 question 6)
