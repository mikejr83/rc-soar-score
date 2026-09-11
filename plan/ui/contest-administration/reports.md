# RC Soar Score User Interface - Reports

Reports are available from the contest workspace for current and completed contests. They identify the contest lifecycle, matrix revision, configuration/calculation version, and whether values are preliminary, estimated, or official.

The reports route for a contest is: `/contests/reports`.

The report area provides overall standings, round and group results, team totals when enabled, class summaries when enabled, missing-score summaries, and score-review indicators. Participant emails, invitation credentials, director audit details, and pending synchronization mutations are excluded.

The user can filter by round, group, team, class, and participant role where applicable. Administrative screens may export the current report or complete contest data through the export workflow. A report generated from a stale revision must identify that revision and offer refresh; it must not present stale values as current.
