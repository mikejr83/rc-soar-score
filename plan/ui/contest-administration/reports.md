# RC Soar Score User Interface - Reports

Reports are available from the contest workspace for current and completed contests. They identify the contest lifecycle, matrix revision, configuration/calculation version, and whether values are preliminary, estimated, or official.

The reports route for a contest is: `/contest-administration/contests/:id/reports`.

The reports area provides a list of reports and documents which can be created for a contest.

The following reports and documents are:

- [Overall Standings](./reports/overall-standings.md)
- [Draw Matrix](./reports/draw-matrix.md)
- [Scoring Sheet](./reports/scoring-sheet.md)
- [Pilot Scoring Cards](./reports/pilot-scoring-cards.md)

## List

The reports page should show a list of the reports that can be run. The reports should be displayed in a manner that shows a title for the report or document and a brief of what the report provides. A stylized graphic or some way to represent the reports can be presented along with this text.

## Displaying

Reports should be displayable without blocking the contest application. They can be opened in their own tab (web) or window (native).

The reports should have a section to select any filtering specific for that report.

Reports will denote what is displayed vs. what is printable.

## Printing

The screen must offer to print the report. This should enable the user to print it using their standard machine printing interface.
