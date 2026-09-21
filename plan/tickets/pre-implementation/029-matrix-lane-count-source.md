# Ticket 029 — Matrix: Lane Count (Configured vs. Derived)

- **Category:** Matrix / Draw
- **Priority:** Low
- **Status:** Open

## Context

It is unclear whether the number of lanes is a contest configuration set by the director, or derived from the number of groups.

## Questions

1. Is the lane count a contest configuration (director sets it), or derived from `⌈N / G⌉`?
2. If configured, can the director set a lane count that is greater than the number of groups?
3. If derived, what happens when the number of pilots changes mid-contest (a pilot drops out) — does the lane count change?
4. Does the lane count affect the feasibility invariant or the draw algorithm?

## Decisions Needed

- Whether lane count is configured or derived.
- How it handles mid-contest pilot count changes.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§3.1, `L = ⌈N/G⌉`)
- `research/glidercore-draw/README.md` (§6 question 6)
