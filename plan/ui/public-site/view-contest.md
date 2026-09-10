# RC Soar Score User Interface - View Contest

The public site shows only the published contest projection and only when the contest is public. It never edits private contest data and never exposes participant email, director audit history, pending mutations, or private review details.

The page will show the contest information:

* Name
* Dates
* Venue
* Current status: In-Progress or Completed

## Route

The route to a publicly published contest should contain the elements that are required to uniquely identify a contest. This way the browser may be refreshed and the contest is not lost. This should enable the URL to be shared with other viewers such that they are taken directly to the contest.

The contest will be broken into views. Views can be set to have their data shown as of a specific round. All of these factors should maintained in the route.

All navigation which takes place within the views should be able to respect native browser back and forward navigation.

## Views

There is a lot of data to convey for a contest. The most important data visualization will be the overall ranking of the pilots known as "Overall Individual Results". The visualization of team scores and individual round data will also be presented as "Team Scores" and "Flight Group Scores".

The "Overall Individual Results" will be the initial view presented when a user navigates to a contest. It will be set to the latest round with scores.

Views will present their data as a point in time. This means that if a user selects a round that is not the current the overall placement, drop-logic, etc should reflect at that point in the contest.

A data grid type paging device will be provided for selecting the scores as of a specific round. Chevrons should go to the beginning and end as well as increment and decrement. A dropdown will be available to select a specific round. This UI component should act as globally to all views for the contest. Meaning, if the user changes the current round to "Round 3" on the "Overall Individual Results" page and they then change the view to "Flight Group Scores", the current round should remain the same and the "Flight Group Scores" page will show its data for the third round.

### Overall Individual Results

When the user navigates to the contest's view page they should be presented with this view. This shows the individual results for pilots as of the selected round. Only pilots are shown in the table, not non-flier roles.

The table should have the following columns:

* Place
* Name
* Country
* Score
* Percentage of Winning Score
* Raw Score
* A column for each round score up to and including the currently selected round.
* Cumulative Penalty

The ranking of individuals in the table is always by their overall score as of the selected round. Ties should be resolved using the contest discipline rules. If no contest discipline rules define tie breaking the pilots are shown as in the same numerical place and are ordered alphabetically by last name.

|Place|Name|Country|Score|Percentage|Raw Score|Round 1|Round 2|Round 3|Penalty|
|-----|----|-------|-----|----------|---------|-------|-------|-------|-------|
|1|John Smith|USA|3000|100%|3000|1000|1000|1000|-|
|2|Mike Gardner|USA|2994|99.8%|2994|998|998|998|-|
|3|Dave Johnston|USA|2880|96%|2880|900|990|990|-|
|3|Chuck Waters|USA|2798|93.3%|2798|990|950|858|-|

### Team Scores

When the user selects team scores the view should show the tabular data for team results. The table's columns will be similar to the "Overall Individual Results" table but will differ in that it is broken into sections to represent each team and the pilots consisting of the team's score. This table does not show any non-flier roles.

The table should have the following columns:

* Team Place
* Team - The name or team number
* Team Score - Calculated per the contest configuration
* Percentage of winning team's score
* Pilot's Name
* Country
* Score
* Raw Score
* A column for each round score up to and including the currently selected round.
* Cumulative Penalty

An example of the table structure is given below:

|Place|Team|Team Score|Percentage|Name|Country|Score|Raw Score|Round 1|Round 2|Round 3|Penalty|
|-----|----|----------|----------|----|-------|-----|---------|-------|-------|-------|-------|
|1|2|5,880|100%|John Smith|USA|3000|3000|1000|1000|1000|-|
|||||Dave Johnston|USA|2880|2880|900|990|990|-|
|2|1|5,792|98.5%|Mike Gardner|USA|2994|2994|998|998|998|-|
|||||Chuck Waters|USA|2798|2798|990|950|858|-|

### Flight Group Scores

The most detailed view is the "Flight Group Scores". This view shows the individual scoring details for a single round. The view still respects the selected round. Instead of a single table, the view shows each group within the round as its own table.

For each group in the round a section is generated. It is headed by the group number and if necessary the re-flight number.

A table will appear for the flight group showing the following information as columns:

* Name - The pilot's name
* Country - The pilot's country
* Time
* Landing score - This is the number of points awarded for the landing. Some disciplines may not have a landing bonus. For those contests this column is not shown.
* Discipline specific scoring details
* Points - The raw points earned by the pilot
* Score - The total points given to the pilot after normalization.
* Penalty - Any penalty incurred on the flight

## View Navigation

The initial view is of the "Overall Individual Results".

A user clicking on a round number header or a round score in the "Overall Individual Results" or "Team Results" should be taken to the "Flight Group Scores" for that round. This involves changing the current round to that round. If the user has clicked a specific pilot's score for a round the resulting view of the "Flight Group Scores" should have that pilot's score scrolled to the upper most portion of the view.

The "Flight Group Scores" and "Team Results" views will have a navigation element to go back to overall results. The "Overall Individual Results" view should have navigation elements to go to "Team Results" or the "Current Round's Flight Group Scores".
