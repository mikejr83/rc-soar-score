# RC Soar Score Business Requirements - Contest Configuration

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Management of the contest is included a web application used in online access. The application is also wrapped in a desktop shell for use when there is no internet or as desired by the contest director.

The contest director will use an application to create contests and and configure contests. The following sections describe the requirements for creating contests, managing basic contest configuration, selecting participation, entering participant information, and managing global data.

## Main Contest Configuration

A contest will need to have various configuration completed before it can be run. Configuration is needed for the contest discipline, the pilots participating, scoring options, scoring rules, and how the rounds and groups are drawn.

### Discipline or Class

The initial and most import piece of configuration is the discipline or "class" of contest. Examples: F3J, F3K, F5J.

Selecting a discipline will indicate if additional configuration necessary. The additional configuration comes down to differences in how scoring, tasks, and drawing of groups occur.

The selection of a discipline can alter contest configuration outside of just what Scoring Rules are necessary. For example, the ALES discipline will set the default "Group Score" under the scoring options to "Time" and the Thermal discipline will set default it to "Normalized".

Initial supported disciplines:

- ALES
- F3J
- F5J
- Thermal Duration

F3L has a placeholder document but is not initially implementable until its scoring rules are defined. The following disciplines are to be considered during design but will not be immediately implemented:

- F3B
- F3K

### Competitors and Pilots

Contests are attended by competitors. Not all competitors are pilots. The application will track all pilots, helpers, or managers that are participating.

Pilots may be organized into teams. The number of team pilots for calculating the team score is necessary if teams are to be used in the contest, otherwise the option is not presented.

An option for giving the participant a unique number for the contest is available. This is an integer value that enables participant to be referred to as "Participant_Type X" where Participant_Type is comes from the role they were assigned or "Pilot" by default and X is that number. The number starts at 1 and increases with the number of pilots in the contest. The number is assigned when the first draw occurs. It cannot be changed afterwards. Pilots added post draw will receive the next number in sequence. _The general use case for the unique numbering for participants is for identifying information placed on specific printed materials._

The option for pilot classes is presented. This is used to classify pilots. Generally, "expert", "advanced", "junior", etc. but can be used for any purpose. This is a reporting only feature. A report may show "the top scoring pilot in each class".

An option to assign roles when selecting participants is presented.

An option to track model information of participants of the Pilot type is presented. When this is enabled and pilots are added to the competition it is necessary for the contest director to fill out the following details about one or more models that the pilot will be entering: The name of the model and the model id. Models are added to that record in the application and can be selected for future contests.

When participants are added to the contest a check is performed with the API for past participation of any contest if the application has connection to the API. If the participant from the local data is identified in the master system then the contest director will have the option of updating their local data with the current information. The application may not have access to the services when participants are being added. A check of all participants is performed when the contest has been published online and the application has a valid connection to the services.

#### Teams

When the option for teams has been selected additional input is required when selecting participation. When participants are added a they must be added to a team. The team is simply a grouping construct. A name is the only required input from the contest director. As participants are added an existing team can be selected by providing the same name or a new one created by providing a new, unique team name.

The team score is always calculated by the totaling the scores of the pilots on the team. The total scores for each pilot on the team are ordered in descending order. The number of scores as defined by the configuration of the number of pilots to use for the team score is taken, starting from the highest score and going to lowest. These scores are summed for the team score. For example, a team of 4 individuals has pilot scores of 4500, 5000, 5120, 5500. The contest has a configuration of the three pilot scores for the team score. The scores 5500, 5120, and 5000 are summed to give the result of 15620 for the team.

Team participation by pilots is locked once a matrix has been created. If a team membership changes the application should request a new draw be performed for a new matrix. However, if the a participant is added as new pilot to the team and was not part of the prior matrix they may be added in randomly given with respect to any other draw options.

Non-flier participants can be added or removed from the team at any point. These participants are used to determine any associated users which can enter scores on behalf of the pilots or for reports.

### Draw Options

The contest director will need to make a determination on how pilots will compete against each other. This is done by specifying options to draw pilots into groups for the number of rounds in the competition.

There is are two modes for the draw that can be selected, "man on man" or "seeded man on man". The "man on man" mode is the default and is used to maximize the number of different pilots that a pilot will fly against. The seeded option uses a new draw after every round. It places pilots with similar progressive scores into groups.

The number of groups per round is required. This is a positive integer number. When the contest director adjusts this number the application will display the number of pilots in which will be allocated to the group. The total number of pilots in the contest may not be split evenly across all groups within the round. Thus, the minimum and maximum number of pilots in a group are shown. The number of groups per round may be influenced by other settings. The minimum number of groups per round will be the maximum number of pilots in a team if team protection is enabled.

An option to enable "Team Protection" is available if pilots are grouped into teams. Two pilots from the same team do not compete against one another in a group. This is used to compute the matrix when performing the draw for groups.

An option to assign lane number is presented. Lane positions can be assigned during the draw. This defaults to "None", pilots are not assigned a lane from which to fly. The contest director may select "Random" to have a random lane assigned to each pilot in the group.

### Seeded Man on Man

When the contest director selects seeded man on man for a draw format an additional option is displayed. This option is an integer value called "Preliminary Man on Man Rounds". This configuration tells the functionality generating the draw to use man on man drawing for the first rounds of the contest where the number of those rounds are equal to the value. This value defaults to 1 and cannot be smaller than 1. At least one round must be flown so that all pilots have a score to seed the pilots for seeded man on man.

Seeded man on man expects the contest director to generate the draw and add it to the matrix after all scores are entered. This format generally has one or more local operators helping the contest director collect and validate scores on the same application installation. When the contest director is performing the initial draw, a total number of rounds intended to be flown value can be specified. This is purely as reference/display. It can be used when printing score cards or for display in the public site.

A common example of a seeded man on man contest:

1. Contest director configures a contest discipline.
2. The configuration for the draw options is set to seeded man on man.
3. Additionally, the contest director indicates that 4 rounds will be flown until the seeding comes into play. The contest director sets the "Preliminary Man on Man Rounds" value to 4.
4. After all other configuration, including pilot selection, the contest director performs the draw for the matrix.
5. The draw will be performed for 4 rounds.
6. The contest director runs the contest and it continues such that participants are entering scores through the four rounds.
7. All scores are entered for the 4 rounds.
8. The contest director has validated/verified all the score data.
9. The contest director draws the next round, round 5.
10. The contest director starts the round and the competitors compete against one another.
11. The scores are entered by the competitors for the round.
12. Steps 8 through 11 are repeated until the contest is completed.

### Scoring Options

A set of options for the "Group Score" are presented:

- Raw Score - Use the raw number of points for each pilot.
- Normalized - The pilot with the most points receives 1000 points and all other pilots are normalized based on their scores.
- Time - The pilot with the best time score receives 1000 points and all other pilots time score is normalized based on their scores. Landing bonuses are then added to the group scores.

The default selection will be "Normalized".

Configuration for calculating a pilot's score will be presented. There are two options, to round to a number of decimal places or truncated after a number of decimal places. The number of decimals places are selectable, 0 - 3.

The contest director can indicate that the worst score for a pilot in a round can be discarded. This is configured by providing the round number after which the score is discarded. The application will provide for at most discarding two rounds per pilot in this manner. Disciplines typically specify the number of rounds completed before a single dropped round. The contest director should have the option to specify up to two. If no round number is supplied for the second then it is to be assumed that there is only one.

### Scoring Rules

Each contest is associated with a discipline, and each discipline defines a default official scoring profile that represents the canonical rules for that format. The scoring model for duration-based disciplines shares a common structure, including flight time, target or working time, points per unit of time, landing bonuses, late-flight handling, and group-score calculation, while each discipline may add its own specific rule variations and validation requirements. A contest director may choose to use the official discipline profile as-is or apply contest-specific overrides for local variations, but any deviation from the official rules must be identified as a contest override rather than a new discipline definition. This approach allows the application to support recognized disciplines, future duration-based disciplines, and limited local rule deviations without requiring a separate scoring architecture for each custom configuration.

Scoring rules for each discipline are covered in detail within their own documents.

## Publishing And Online Configuration

Scoring for the contest involves pilots, their helpers, or the contest director and local operators entering scores into the application. Further, interested parties may want to monitor ongoing contests or look at previously held contests. The publishing and online configuration section enables contest directors to determine if and how these things are performed.

Contests can be run by a contest director strictly offline. The desktop version of the application is used, participants are manually entered, and the contest has scores entered into the system by an official. This can vary slightly, where the contest director performs all those functions offline except they wish to publish the finalized scores after the completion of the contest. Finally, a contest director may desire to have the contest run such that they pull participant information from the service API, have participants enter their scores, those scores update on the public site as they change, and they perform the role of validating those scores.

A contest must be published for it to appear on the public site.

When the contest is published several things occur:

- Any participants that have been included in the contest are checked against a global participant list.
- Participants that can be linked to the global list and have local deviations from the global list for their info are shown to the contest director.
- The contest director can decide to update participants' local info with what was downloaded.
- The current participant list is uploaded with all participants and their types being linked to the contest.
- If teams are being used, team entries are created and participants linked to the teams.
- The model information, if being tracked for the contest, is is linked to each pilot for the contest.
- The contest defaults to private mode. It isn't shown on the public web site.

The contest director will be able to make a contest public or private. This affects if the contest can be searched for and is displayed on the public site. A participant's participation in a contest is not shown in the global site if a contest is marked private.

The contest director will have the option to lock scoring. Participants cannot enter scores when this is enabled.

An option is presented for the contest director to allow participants to make review requests for previously entered scores.

The contest director will have options to dictate how scores are displayed for the contest on the public site. Contest directors will use this to help control how scores and contest progression is presented. There will be the following options:

- Automatic score updates
- Updates at assumed round completion
- Manual / Require validation before score calculation

The default for this selection is "Updates at assumed round completion".

Automatic score updates will update as soon as the participants enter the data. The public site will be showing the most up to date information as it is entered.

When the "Updates at assumed round completion" is selected the scores update on the public site will show when all scores have been entered by participants for the round.

The "Manual" setting requires the contest director to mark the round as completed or have all the scores marked as official.
