# Reports & Documents - Overall Standings

The overall standings show overall pilot placement. It shows the pilots in order of their placement with each of the scores they received over the contest. It may contain additional information about a pilot's score for each flight if the discipline contains that information.

## Heading

The header for the report should be "Overall Results - {Contest_Name}". A subheading with the contest details is shown below it.

## Basic Layout

This report is tabular in nature. Each row is for a pilot. The rows are ordered by the pilot's placing at the last row shown.

The columns in order:

1. Rank - The overall rank of the pilot.
2. Pilot's name
3. Total score - This is shown as per the contest settings (round/truncating and decimals).
4. Any optional selected columns
5. Round scores.

Starting with the 5th column (after the optional columns) are columns for each round. If there were 14 rounds flown, the round 1 column would start and each column to the right of that would be the next round, ie the column after round 1 would be round 2.

The standard layout for this report should be in landscape. The columns for the rounds should be fixed width.

A dropped round's cell should be highlighted.

## Printing

This report will require considerations when printing.

A report showing a contest with many rounds and configured to show all the optional data may overflow on the horizontal axis. Subsequent pages will need to show the rounds which could not fit on the page. When this occurs all of the optional columns do not need to be shown.

Overflowed page columns:

1. Rank
2. Pilot Name
3. Additional rounds that couldn't be fit on the previous page.

## Options

These are optional columns that can be shown on the report. available)

- Percentage of total - This is the percentage of the points the pilot achieved based on the winner. The winner would be 100%. If a pilot managed only to receive 5000pts and the winner had 10,000pts, that pilot would have 50%.
- Raw Score - The total of all flight scores. This would be the "Total score" plus any of the dropped rounds. This provides an overview of how well a pilot did if there was no drop. _This is not the raw score for each round._
- Team\*
- Pilot Number\*
- Pilot Class\*

\*: Only enabled when the contest has this configuration option enabled.

**Flight Details** - Flight details adds additional data into each of the cells for the round score. In smaller text under the round score are the values that contributed to the pilots score. This depends on the discipline being flown.

F5J example:

- Time
- Landing (the points, not display value)
- Launch Height

F3J example

- Time
- Landing

**Provisional** - This report may be run mid contest. If this is selected it should show up to the last round with scores even if that round does not have all scores. Regardless of this being selected or not, rounds that have no scores not be shown. This should default to checked if there are more rounds that have not been scored.

## Filtering

The report needs to be able to be filterable so that a select set of rounds can be selected. It should default to "All rounds". An lower and upper bound for rounds (inclusive) should be able to be set so such that the output show from the lower to the upper rounds.
