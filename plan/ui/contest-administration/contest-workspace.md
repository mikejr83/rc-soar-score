# RC Soar Score User Interface - Contest Workspace

The contest workspace is the director's landing page after opening a contest. It shows the contest identity, the independent state values from [overview.md](./overview.md), and navigation to configuration, matrix, scoring, reports, publication, and audit/synchronization details.

This page is located at the route: `/contest-administration/contests/:id/workspace`.

## Configuration

Configuration is grouped into identity, discipline and scoring rules, participant options, participants, draw options, scoring access, administration lock, and public update policy. Each group shows its current revision and whether editing it would invalidate the matrix or derived scores.

`Save configuration` never draws a matrix. Saving a valid configuration may move a contest from `Created` to `Configuring`; it never creates a matrix implicitly. Drawing happens only on the Matrix page. The configuration page shows whether a draw is possible and links to the Matrix page: a draw is possible only when required configuration is valid, at least two scoring pilots exist, and the contest is not locked or completed. When it is not, the configuration page shows the reasons.

After a successful draw, the configuration page shows the matrix revision, minimum and maximum group size, and which saved settings differ from those the matrix was drawn with. In seeded mode, the workspace shows whether the preliminary rounds are complete and whether another round can be drawn.

## Layout by lifecycle

The workspace is one page that rearranges itself as the contest moves through its lifecycle. The rule lives in `WorkspaceLayoutPlan` (`lib/services/workspace/workspace_layout_plan.dart`); widgets read the plan and never decide visibility themselves. "Before Running" means `Created`, `Configuring` or `Ready`.

Main column, wide layout, top to bottom:

| Stage          | Sections                                                                                |
| -------------- | --------------------------------------------------------------------------------------- |
| Before Running | next step, setup checklist, round progress (only once a matrix exists), recent activity |
| Running        | next step, needs attention, round progress, recent activity                             |
| Completed      | next step, round progress, needs attention (only when it has items), recent activity    |

The side column is always the control cards, then contest facts. On a narrow window the page is one column: the main column without recent activity, then controls, facts and recent activity.

Control cards, top to bottom:

| Stage          | Cards                                                                     |
| -------------- | ------------------------------------------------------------------------- |
| Before Running | lifecycle, scoring, administration, publication, archive                  |
| Running        | scoring, overall results, publication, administration, lifecycle, archive |
| Completed      | publication, lifecycle, scoring, administration, archive                  |

The overall-results card exists only while Running, and archive is always last. Complete contest is an action on the lifecycle card, offered only while Running.

## State actions

State actions live on the workspace. They are contest controls, not configuration, so the configuration page does not repeat them. The shell's status summary stays read-only and links to the matching workspace control.

Actions are explicit and state-driven:

- Open or close participant scoring access independently of lifecycle.
- Lock or unlock administration with a confirmation that identifies blocked mutations.
- Complete a running contest after showing missing scores and unflown rounds; completion closes participant scoring.
- Publish or update the public projection through the publication flow.
- Archive or unarchive local contest data without deleting it.

Every transition shows the current value, requested value, affected scope, and result. A stale revision or rejected transition leaves the workspace unchanged and provides retry or refresh.

## No navigation summary

The workspace does not repeat the rail. Every link on the page sits next to the fact it acts on (a checklist item, a round tile, a needs-attention item); there is no list of page cards.

Completed contests use a read-only workspace except for authorized score correction and publication actions.
