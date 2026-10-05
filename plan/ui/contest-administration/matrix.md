# RC Soar Score User Interface - Matrix

The matrix and draw page is located at the route: `/contest-administration/contests/:id/matrix`.

The matrix view shows one contest matrix revision with round and group navigation. Each assignment displays the participant number when enabled, pilot name, team, role, lane when lane mode is not `None`, and assignment status. Non-flying participants are not assigned score slots.

The director can inspect the fairness summary, add future rounds, redraw permitted unscored rounds, and move or replace pilots only where the matrix and lifecycle rules allow it. Any action that affects a scored assignment is blocked or routed to an explicit reset, correction, or re-flight workflow; the UI must not silently reinterpret existing scores.

**Exception (per pre-implementation ticket [021](../../tickets/pre-implementation/021-state-mid-contest-redraw.md)):** the director may explicitly re-draw rounds that already have scores. This is available on this page as a warned action: the UI defaults to and steers toward future (unscored) rounds, and selecting scored rounds requires acknowledging a high-importance warning that those rounds' recorded scores will be invalidated and removed. On confirmation the affected round's score placeholders/attempts are voided to audit history and the round is reset to not-flown with new groupings.

For seeded man-on-man, the view shows preliminary rounds, whether scores are complete and validated, and whether the next seeded round can be drawn. A draw operation shows the target rounds, configuration revision, matrix revision, and warning before confirmation. The result displays success, rejected constraints, or a recoverable failure without losing the prior matrix.

## Moving a scored pilot

Moving a pilot who has an accepted score is an explicit **reset**. The confirmation states that the existing score stays in the history and stops counting, and that the pilot must enter the score again in the destination group. A score is never transferred between groups.

The director can also reset a score in place, by moving the pilot to the same slot, for a score that was entered in the wrong place. The pilot's assignment does not change and the score returns to not entered.

## Adding a late pilot

A pilot added after scores exist is placed in groups that have not flown and have space, up to the largest group size of the original draw. The view identifies these late-add assignments. If no such group has space in a round, say so and offer a redraw of the later unscored rounds; the application never redraws on its own. Rounds the late pilot never makes up count as zeros, and the UI labels them that way.

## Re-flights

The director awards a re-flight for a round with a reason, and chooses one of three methods. The application presents the methods in the priority the discipline defines, but the director decides:

- **Move to a group:** move the pilot to another group in the same round. If the choice deviates from the discipline's rules, warn the director.
- **Random draw:** draw a new group from the eligible pilots, show the draw before it is finalized, and let the director record a pilot who declines.
- **Re-fly the entire group:** the whole group flies again.

Re-flight groups are numbered after the regular groups of the round, and each is headed with the group it re-flies, for example "Group 3, re-flight 1". The view shows each re-flight's status (`Proposed`, `DrawPending`, `AwaitingResponses`, `ReadyToFly`, `Finalized`, or `Cancelled`). A re-flight never overwrites the original flight. Offers to pilots, their responses, and notifications are optional in the first release; the director can always finalize without them.

## Group locks

The director can lock and unlock a group. A locked group shows its lock state in the group header, and blocks participant changes and later corrections to every score flown in it until it is unlocked. Locking a group first lists any outstanding review requests in the group for the director to resolve.
