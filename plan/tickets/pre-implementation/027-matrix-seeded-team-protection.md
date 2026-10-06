# Ticket 027 — Matrix: Seeded + Team Protection

- **Category:** Matrix / Draw
- **Priority:** Medium
- **Status:** Decided (see [#77](https://github.com/mikejr83/rc-soar-score/issues/77))

## Context

The research doc notes that seeded man-on-man with team protection needs a defined fallback or should be explicitly forbidden. The current plan does not address this combination.

## Questions

1. Should seeded man-on-man and team protection be supported together?
2. If yes, what is the fallback when the minimal rank-displacement swap cannot resolve a team clash in a seeded round?
3. If no, should the wizard prevent selecting both, and what error message is shown?
4. Does the combination change the feasibility invariant (GroupsPerRound ≥ max team size)?

## Decisions Needed

- Whether the combination is supported or forbidden.
- The fallback algorithm or validation error if supported.

## Sources

- `research/glidercore-draw/README.md` (§6 question 4)
- `plan/architecture-requirements/matrix-draw.md` (§2.1, §6 step 4)
