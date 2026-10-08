# RC Soar Score User Interface - Contest Workspace

The contest workspace is the director's landing page after opening a contest. It shows the contest identity, the independent state values from [overview.md](./overview.md), and navigation to configuration, matrix, scoring, reports, publication, and audit/synchronization details.

This page is located at the route: `/contest-administration/contests/:id/workspace`.

## Configuration

Configuration is grouped into identity, discipline and scoring rules, participant options, participants, draw options, scoring access, administration lock, and public update policy. Each group shows its current revision and whether editing it would invalidate the matrix or derived scores.

`Save configuration` never draws a matrix. Saving a valid configuration may move a contest from `Created` to `Configuring`; it never creates a matrix implicitly. Drawing happens only on the Matrix page. The configuration page shows whether a draw is possible and links to the Matrix page: a draw is possible only when required configuration is valid, at least two scoring pilots exist, and the contest is not locked or completed. When it is not, the configuration page shows the reasons.

After a successful draw, the configuration page shows the matrix revision, minimum and maximum group size, and which saved settings differ from those the matrix was drawn with. In seeded mode, the workspace shows whether the preliminary rounds are complete and whether another round can be drawn.

## State actions

State actions live on the workspace. They are contest controls, not configuration, so the configuration page does not repeat them. The shell's status summary stays read-only and links to the matching workspace control.

Actions are explicit and state-driven:

- Open or close participant scoring access independently of lifecycle.
- Lock or unlock administration with a confirmation that identifies blocked mutations.
- Complete a running contest after showing missing scores and unflown rounds; completion closes participant scoring.
- Publish or update the public projection through the publication flow.
- Archive or unarchive local contest data without deleting it.

Every transition shows the current value, requested value, affected scope, and result. A stale revision or rejected transition leaves the workspace unchanged and provides retry or refresh.

## Navigation summary

- `Scoring` opens official score entry at the latest relevant round and group.
- `Reports` opens current or completed results and export actions.
- `Publication` shows publication history, visibility, public update policy, and publish/delist actions.
- `Participants` opens contest-specific participant data without changing reusable profiles.
- `Matrix` opens round/group assignments, lane positions, moves, and re-flight actions where permitted.

Completed contests use a read-only workspace except for authorized score correction and publication actions.
