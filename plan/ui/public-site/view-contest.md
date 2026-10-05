# RC Soar Score Public Site UI - View Contest

The public site shows only the published contest projection. A `Public` contest can be found through search and viewed by anyone; an `Unlisted` contest is not searchable but can be viewed by anyone with its link. It never edits private contest data and never exposes participant email, director audit history, pending mutations, or private review details.

The page will show the contest information:

- Name
- Dates
- Venue
- Current status: In-Progress or Completed
- For a seeded contest with an intended total, the round count, for example "Round 4 of 8"

Pilot names come from the participant's public profile when they have linked one, so the participant controls the name shown; otherwise the name and country recorded by the director are shown. A pilot who has redacted their details is shown as `<pilot details private>` in every view.

## Route

The route to a publicly published contest should contain the elements that are required to uniquely identify a contest. This way the browser may be refreshed and the contest is not lost. This should enable the URL to be shared with other viewers such that they are taken directly to the contest.

The contest will be broken into views. Views can be set to have their data shown as of a specific round. All of these factors should maintained in the route.

All navigation which takes place within the views should be able to respect native browser back and forward navigation.

The base route for viewing a contest will be `/results/contests/:contestId`. If the contest does not exist for the given identifier in the route a not-found page specific to a contest not being found should be shown. The route should not change. This page is detailed in the [`contest-not-found.md`](./contest-not-found.md) document.

## Views

There is a lot of data to convey for a contest. The most important data visualization will be the overall ranking of the pilots known as "Overall Individual Results". The visualization of team scores and individual round data will also be presented as "Team Scores" and "Flight Group Scores".

The "Overall Individual Results" will be the initial view presented when a user navigates to a contest. It will be set to the latest round with scores.

Views will present their data as a point in time. This means that if a user selects a round that is not the current the overall placement, drop-logic, etc should reflect at that point in the contest.

A data grid type paging device will be provided for selecting the scores as of a specific round. Chevrons should go to the beginning and end as well as increment and decrement. A dropdown will be available to select a specific round. This UI component should act as globally to all views for the contest. Meaning, if the user changes the current round to "Round 3" on the "Overall Individual Results" page and they then change the view to "Flight Group Scores", the current round should remain the same and the "Flight Group Scores" page will show its data for the third round.

The route will change when the round changes: `/results/contests/:contestId/rounds/:roundNumber`.

### Contest Not Available

A contest that has never been published has no public record, so its route shows the [contest not found](./contest-not-found.md) page. The page does not reveal whether a private contest exists.

A `Delisted` contest has been removed from public access by an administrator. Its route also shows the contest not found page, and no contest data is returned.

An `Unlisted` contest is not an error: it is displayed normally to anyone who has its link. It is only excluded from search and listings.

### Hidden Overall Results

The director may hide overall results, which withholds overall scores and placing as of a recorded round while the contest continues. Rational reasons for doing so include:

- There is a major discrepancy in entered scores and the director is working to resolve them.
- Winners are being announced and the director does not wish to spoil the surprise.

While results are hidden, every view shows a banner stating that the contest director is showing overall standings as of round N, and that they will be shown again later. The "Overall Individual Results" and "Team Scores" views show their standings only through round N, and the round selector cannot move their standings past it. Round scores and the "Flight Group Scores" view stay current for every round. The page should check again after an interval (15 minutes) and remove the banner when hiding has ended.

### Overall Individual Results

When the user navigates to the contest's view page they should be presented with this view. This shows the individual results for pilots as of the selected round. Only pilots are shown in the table, not non-flier roles.

The table should have the following columns:

- Place
- Name
- Country
- Score
- Percentage of Winning Score
- Raw Score
- A column for each round score up to and including the currently selected round.
- Cumulative Penalty - the total of the cumulative penalties applied, which is deducted from the score

The ranking of individuals in the table is always by their overall score as of the selected round. The service providing the data will prepare the places for each of the pilots. The service maintains the responsibility for looking at the contest's discipline and applying any tie-breaking rules. This data will, however, indicate any unresolvable ties. These ties should be shown as in the same numerical place and are ordered alphabetically by last name. An indicator that those pilots are tied should be shown.

Each round score includes any flight penalty entered for that flight. A cumulative penalty is shown in the round column of the flight where it was given, as well as in the penalty total.

| Place | Name          | Country | Score | Percentage | Raw Score | Round 1 | Round 2 | Round 3 | Penalty |
| ----- | ------------- | ------- | ----- | ---------- | --------- | ------- | ------- | ------- | ------- |
| 1     | John Smith    | USA     | 3000  | 100%       | 3000      | 1000    | 1000    | 1000    | -       |
| 2     | Mike Gardner  | USA     | 2994  | 99.8%      | 2994      | 998     | 998     | 998     | -       |
| 3     | Dave Johnston | USA     | 2880  | 96%        | 2880      | 900     | 990     | 990     | -       |
| 3     | Chuck Waters  | USA     | 2880  | 96%        | 2880      | 990     | 950     | 940     | -       |

This view will use the same route as the root of the contest view.

### Team Scores

When the user selects team scores the view should show the tabular data for team results. The table's columns will be similar to the "Overall Individual Results" table but will differ in that it is broken into sections to represent each team and the pilots consisting of the team's score. This table does not show any non-flier roles.

The table should have the following columns:

- Team Place
- Team - The name or team number
- Team Score - Calculated per the contest configuration
- Percentage of winning team's score
- Pilot's Name
- Country
- Score
- Raw Score
- A column for each round score up to and including the currently selected round.
- Cumulative Penalty

An example of the table structure is given below:

| Place | Team | Team Score | Percentage | Name          | Country | Score | Raw Score | Round 1 | Round 2 | Round 3 | Penalty |
| ----- | ---- | ---------- | ---------- | ------------- | ------- | ----- | --------- | ------- | ------- | ------- | ------- |
| 1     | 2    | 5,880      | 100%       | John Smith    | USA     | 3000  | 3000      | 1000    | 1000    | 1000    | -       |
|       |      |            |            | Dave Johnston | USA     | 2880  | 2880      | 900     | 990     | 990     | -       |
| 2     | 1    | 5,874      | 99.9%      | Mike Gardner  | USA     | 2994  | 2994      | 998     | 998     | 998     | -       |
|       |      |            |            | Chuck Waters  | USA     | 2880  | 2880      | 990     | 950     | 940     | -       |

This view will use the route `/results/contests/:contestId/teams/results` as its root when the latest contest round is selected or no round has been selected. The route `/results/contests/:contestId/teams/results/rounds/:roundNumber` is used if a round other than the latest is selected.

A user navigating to this route will be redirected to the contest's root route if the contest does not support teams.

### Flight Group Scores

The most detailed view is the "Flight Group Scores". This view shows the individual scoring details for a single round. The view still respects the selected round. Instead of a single table, the view shows each group within the round as its own table.

For each group in the round a section is generated. It is headed by the group number and if necessary the re-flight number.

A table will appear for the flight group showing the following information as columns:

- Name - The pilot's name
- Country - The pilot's country
- Time
- Landing score - This is the number of points awarded for the landing. Some disciplines may not have a landing bonus. For those contests this column is not shown.
- Discipline specific scoring details
- Points - The raw points earned by the pilot
- Score - The total points given to the pilot after normalization.
- Penalty - The total deducted from the flight: the discipline's penalties plus any flight penalty entered with the score

This view will use the route `/results/contests/:id/rounds/:roundNumber/flight-groups`. This page is always specific to a round.

## View Navigation

The initial view is of the "Overall Individual Results".

A user clicking on a round number header or a round score in the "Overall Individual Results" or "Team Results" should be taken to the "Flight Group Scores" for that round. This involves changing the current round to that round. If the user has clicked a specific pilot's score for a round the resulting view of the "Flight Group Scores" should have that pilot's score scrolled to the upper most portion of the view.

The navigation between the views should retain the last selected round.

The "Flight Group Scores" and "Team Results" views will have a navigation element to go back to overall results. The "Overall Individual Results" view should have navigation elements to go to "Team Results" or the "Current Round's Flight Group Scores".
