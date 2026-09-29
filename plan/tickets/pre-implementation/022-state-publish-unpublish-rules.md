# Ticket 022 — State Machine: Publish/Unpublish Rules for Results

- **Category:** Contest State Machine
- **Priority:** Medium
- **Status:** Open

## Context

Whether a published round's results can be unpublished, and what happens to the public site if they are, is not defined.

## Questions

1. Can a published round's results be unpublished?
2. If so, what does the public site show — stale data, an error, or the previous round's data?
3. Can a round be republished after being unpublished, and does it get a new revision number?
4. Does unpublishing a round affect the cumulative standings of subsequent rounds?
5. Is unpublishing a director-only action?

## Decisions Needed

- Whether unpublish is allowed and its effect on the public site.
- How unpublishing interacts with the calculation revision sequence.

## Sources

- `plan/ui/public-site/view-contest.md`
- `plan/architecture-requirements/data/scores-and-results.md`
