# RC Soar Score User Interface - Matrix

The matrix and draw page is located at the route: `/contest-administration/contests/:id/matrix`.

The matrix view shows one contest matrix revision with round and group navigation. Each assignment displays pilot number when assigned, pilot name, team, lane when enabled, and assignment status. Non-flying participants are not assigned score slots.

The director can inspect the fairness summary, add future rounds, redraw permitted unscored rounds, and move or replace pilots only where the matrix and lifecycle rules allow it. Any action that affects a scored assignment is blocked or routed to the explicit correction/re-flight workflow; the UI must not silently reinterpret existing scores (moving a pilot is the one exception, below). **Exception (per ticket 021):** the director may explicitly re-draw rounds that already have scores. This is available on this page as a warned action: the UI defaults to and steers toward future (unscored) rounds, and selecting scored rounds requires acknowledging a high-importance warning that those rounds' recorded scores will be invalidated and removed. On confirmation the affected round's score placeholders/attempts are voided to audit history and the round is reset to not-flown with new groupings. **First release (#264):** the page has two actions, Add rounds and Redraw unscored rounds. There is no round picker: a redraw starts at the first round after the last one with scores, so with nothing scored it replaces the whole matrix. Redrawing rounds that have scores (the exception above) is #616.

For seeded man-on-man, the view shows preliminary rounds, whether scores are complete and validated, and whether the next seeded round can be drawn. A draw operation shows the target rounds, configuration revision, matrix revision, and warning before confirmation. The result displays success, rejected constraints, or a recoverable failure without losing the prior matrix.

## Moving a pilot (#263)

The highlighted pilot's tile has a "Pilot actions" menu with **Move**. It is off, with the reason beside it, when administration is locked or the contest is not Ready or Running. A late add is not done from the matrix: a pilot added on the participants page is seated in every round by the late placement call.

The Move dialog asks for a round, a group, a lane when the contest uses lanes, and a required reason. A move is sent with a client-generated id, so a retry cannot move twice, and the returned matrix replaces the grid.

- **Any group of any current round can be chosen** except the ones below, including a group that has scores and a round that appears completed. Those are marked **Not ideal** with the reason, as is a group with a teammate (when team protection is off). Every other group is marked **Recommended**.
- **Cannot be chosen:** a group the pilot already flies in (their current group, or the group they hold in the target round); a locked group or a group of a locked round ("unlock the group first"); a group with a teammate when team protection is on. There is no lock override in the UI, and a pilot in a locked group or with a locked score cannot be moved until it is unlocked.
- **A scored assignment can be moved.** The dialog warns that the score is discarded (the server keeps it in the history as a reset), that this is not the standard way to correct a flight, and asks the director to check; the confirm button reads "Discard score and move".
- A moved pilot shows a **Moved** label (icon and text) in the grid; the pilot panel lists the reason.
- A refused move leaves the grid unchanged and the dialog open with what was entered. A refusal that means the matrix or contest changed offers Reload.
- No drag and drop.
