# Reports & Documents - Draw Matrix

The draw matrix shows each round and group and the pilots flying in those rounds.

## Heading

The heading should show the contest name across the top along with "Flight Matrix". A sub-heading should show the venue and the dates.

## Basic Layout

This is a tabular layout. The headers are:

- Pilot Name
- Lane Number\*\*
- Team\*
- Pilot Number\*
- Pilot Class\*

\*: Only enabled when the contest has this configuration option enabled.

\*\*: Shown only when lanes are turned on.

The rows in the table run in order of the round and group:

1. Round 1, Group A
2. Round 1, Group B
3. Round 1, Group C

...

7. Round 3, Group A
8. Round 3, Group B
9. Round 4, Group C

A row should appear as a header denoting where the round starts. A row should appear as a header where the group starts. These rows can column span all columns in the table.

## Options

**Compact Mode**: An option to turn on this mode will be available to the user.

- The fonts will be smaller.
- Minimal padding in the table.
- Two columns of tables.

**Additional Pilot Info**: This option is disabled and not available when compact mode is enabled. The table will show the pilot's club and FAI or National ID. The FAI or National ID is are options when this is enabled.

## Filtering

The report needs to be able to be filterable so that a select set of rounds can be selected. It should default to "All rounds". An lower and upper bound for rounds (inclusive) should be able to be set so such that the output show from the lower to the upper rounds.
