# Ticket 019 — Access: Public Site Visibility of In-Progress Scores

- **Category:** Access / Permissions
- **Priority:** Medium
- **Status:** Open

## Context

The public update policy has three modes (automatic, round completion, manual). The visibility of draft/unconfirmed scores to the public is not specified.

## Questions

1. In "automatic" mode, are draft scores (entered by a helper but not confirmed by the pilot) visible to the public?
2. In "round completion" mode, are scores visible as soon as the round is marked complete, or only after all pilots in the round have confirmed?
3. Can the public see a score that has been entered but is in a "pending review" state?
4. How does the public site handle a group where some scores are confirmed and others are still in progress?

## Decisions Needed

- Visibility rules for draft vs. confirmed scores per public update mode.
- How in-progress groups are displayed on the public site.

## Sources

- `plan/business-requirements/managing-system.md`
- `plan/ui/public-site/view-contest.md`
