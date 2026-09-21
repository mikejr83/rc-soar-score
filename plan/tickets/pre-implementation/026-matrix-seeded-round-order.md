# Ticket 026 — Matrix: Seeded Round Order (Leaders First vs. Last)

- **Category:** Matrix / Draw
- **Priority:** High
- **Status:** Open

## Context

`matrix-draw.md` puts leaders in Group 1 (they fly first). GliderScore puts lowest scorers in Group 1 (leaders fly last). The research doc flags this as a direct contradiction.

## Questions

1. In seeded man-on-man mode, should leaders fly first (Group 1) or last (Group G)?
2. If leaders fly last, does the tier assignment reverse (rank N in Group 1, rank 1 in Group G)?
3. How does the team-protection swap work with the reversed ordering?
4. Does the choice affect the fairness metric (pairwise meeting counts) or only the perceived fairness?

## Decisions Needed

- The group ordering for seeded rounds (leaders first or last).
- How this interacts with team-protection displacement.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§6, step 3)
- `research/glidercore-draw/README.md` (§1, §6 question 3)
