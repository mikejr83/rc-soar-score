# RC Soar Score User Interface - Contest Workspace

The contest workspace is the director's landing page after opening a contest. It shows the contest identity, the independent state values from the [contest state presentation](./README.md#contest-state-presentation), and navigation to configuration, matrix, scoring, reports, publication, and audit/synchronization details.

This page is located at the route: `/contest-administration/contests/:id/workspace`.

## Configuration

Configuration is grouped into the four groups defined in [contest-options.md](../../data-model/contest-options.md): structural, scoring rules, recalculating, and presentation. Identity (name, dates, venue) and the participant list are edited alongside them. Each group shows its current revision and whether it can still change in the current lifecycle state:

- **Structural** (teams, team protection, roles, draw mode, preliminary rounds, lane mode): free before the draw, allowed with a warning after the draw and before any score, fixed once running.
- **Scoring rules** (the discipline's field values and the landing table): free until running, then fixed. The landing table locks at the first landing score.
- **Recalculating** (group score mode, rounding, decimal places, dropped rounds, tie-breaker, team pilot count): changeable until completion. A change recomputes the stored results.
- **Presentation** (classes, models, participant numbers, review requests, public update mode, intended total rounds): changeable until completion.

The discipline never changes once set. Explain next to the scoring-rules group that the discipline field values and the landing table are fixed once the contest is running, so a mistake must be fixed before the first score is entered. A guided correction for such mistakes is planned for a later version. The administration lock blocks every configuration change while it is on.

The workspace must distinguish `Save configuration` from `Draw matrix`. Saving a valid configuration may move a contest from `Created` to `Configuring`; it never creates a matrix implicitly. `Draw matrix` is enabled only when required configuration is valid, at least two scoring pilots exist, and the contest is not locked or completed. Groups per round is entered with the draw, not saved as configuration. Before a redraw, show the affected matrix revision and whether existing scores prevent the change.

A structural change after a draw never alters existing assignments. Saving it warns the director and offers to redraw the unscored rounds. The director decides, and the warning explains that printed matrix cards for redrawn rounds must be reprinted.

After a successful draw, show the matrix revision, minimum and maximum group size, fairness summary when available, and actions to inspect groups or redraw according to lifecycle rules. In seeded mode, show whether the preliminary rounds are complete and whether another round can be drawn.

## State actions

Actions are explicit and state-driven:

- Open or close participant scoring access independently of lifecycle.
- Lock or unlock administration with a confirmation that identifies blocked mutations.
- Lock or unlock scores at the score, group, round, and contest level. Applying a lock first lists any outstanding review requests in its scope, and the director resolves or dismisses each one before the lock applies.
- Hide or show overall results. Hiding keeps the standings at the round that was current when it was turned on (the round in progress, or the last completed round). It ends when the director turns it off, when the contest completes, or 24 hours after it was turned on, whichever comes first. While on, show the round the standings are held at and when hiding will end.
- Complete a running contest after showing missing scores and unflown rounds; completion closes participant scoring and ends results hiding.
- Publish or update the public projection through the publication flow.
- Archive or unarchive local contest data without deleting it.
- Show the installation where the contest is currently active, for example "Contest is currently active on Field laptop", with the `Reactivate as Primary and Sync` action when this installation is not the active one (see [offline-ui.md](offline-ui.md)).

Every transition shows the current value, requested value, affected scope, and result. A stale revision or rejected transition leaves the workspace unchanged and provides retry or refresh.

## Navigation summary

- `Scoring` opens official score entry at the latest relevant round and group.
- `Reports` opens current or completed results and export actions.
- `Publication` shows publication history, visibility, the public update policy, and the publish and delist-request actions. Visibility is `Unlisted` or `Public`, and the first publish defaults to `Unlisted`. A published record removed by an administrator shows `Delisted`, which the director cannot change.
- `Participants` opens contest-specific participant data without changing reusable profiles.
- `Matrix` opens round/group assignments, lane positions, moves, and re-flight actions where permitted.

Completed contests use a read-only workspace except for authorized score correction and publication actions.
