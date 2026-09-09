# RC Soar Score Architecture - Entities/Data

These are the conceptual data requirements for the system. Unique identifiers for the resulting entities are necessary but not explicitly shown here. Linking data also implies foreign keys to the related entities.

There are two locations where data is stored, in the main API layer and locally within the PWA application. This places data in 3 states:

* Local data
* Data sent to the API layer for storage as a back-up measure.
* Published data

A contest director that does not have an account will not have data stored in the remote system for back up. They will be able to publish public contests.

Local data is what contest directors generate using the PWA. When the user is using the web site it is assumed that the data will be automatically stored in the greater system linked to their account. When the contest director is using the offline application it is assumed that the data is stored primarily locally and is then synced to the API

## Users

Users are accounts which have been created to track data in the system. These will contain the basic information about someone that is using the system. This is used to defined ownership over other entities.

* First and last name
* Email address
* Identity Provider identifier

## Contest

This is the main entity for tracking a contest, its configuration, participants, scores, etc.

The following properties are common to all entities of this type and are required:

* Name
* Start and end date
* Host - A simple name for where the contest is taking place. This could be the club name hosting the contest
* Location - City, State, Country
* Discipline
* Use Teams
* Use Pilot Start Numbers (Unique number per pilot)
* Use Classes
* Use Roles
* Use Models
* Lane Assignment
* Draw Mode
* Groups Per Round

## Published Contest

A contest is published and a new entity is created to track this data. This streamlines the data shown and simplifies the data model for showing ongoing contests and past results on the public site.

Data from the contest being published will be cloned to this entity. If the contest changes and a publish occurs it may be update it with new information.

## Participant

A participant is the generic term used for a pilot, a helper, a team manager, etc. They do not have a class until they are linked to a specific contest. Participants are kept as a generic collection as over time contest directors can select from these entities to add them to a contest in a various capacity.

This makes the linking between participants and contests a \*:\* relationship. A contest can have many participants and a participant can have many contests.

Scores are always associated back to a participant.

* First and Last Name
* Country
* Club
* FAI Number
* City
* State
* Email

## Participant Contest Link

A linking is created between a participant and a contest when a contest director adds the participant to the contest. If the contest is using roles then the role of participation is recorded.

* Class name - The pilot classification: Expert, Senior, Junior, Female, etc.
* Role name - The name of the role the user is assuming for the contest. This is just used for display purposes
* Role type - Indicates the link as a pilot or non-flier. Pilots are the only ones to receive scores. Non-fliers are considered helpers and only role within the application is for helping enter scores for pilots which are on their team.
* Unique identifier - Used when a unique identifier number is selected for participants in the contest.
* Scoring UUID - These are generated when the participant is added. It is a non-sequential identifier used for the URL where the participant will enter scores.
* Team - Only set if the contest is utilizing teams. Used to group participants for team functionality.

## Participant Model Link

If the contest is configured to track models per pilot then each model is linked to the contest though the participant link. This enables the participant to have different models at different contests.

* Model name
* Manufacturer
* Contest Model Identifier

## Participant User Link

A participant may be linked to a user account. When a user account that is created a check is run against the participant entities. If no participant entity with that email exists a participant entity is created and a link created between the participant and the user account. If the search finds a participant that exists with the same email then only the link between the user account and the participant is created.

This is kept as a link instead of a foreign relation because future development may see a user account being related to multiple participants. This would be indicative of a situation where emails changed or a new user account had to be created.

## Rounds

Rounds are linked to a contest. This entity facilitates groups of pilots participating in the round. Rounds are created and linked to a contest when the draw is performed.

The key data point on this entity is "Round Number". This is basically an ordinal positioning integer value that indicates "First Round", "Second Round", and so forth.

## Groups

A group represents a collection of pilots competing against one another. These are created during the draw. Each round will consist of a number of groups, a 1:* relationship between rows and groups.

The group entity has the following properties:

* Group Number - This is represented as an ordinal positioning integer. In the UI it may be displayed as "Group 1", "Group 2", etc. or "Group A", "Group B", etc.

## Group Scores

This entity represents the scores for pilots within a group. Each pilot that is assigned to a group will have a group score created regardless of if a score is actually entered. It is the placeholder for a score to be recorded.

The common properties that will need to be tracked for all scores are:

* Group Link
* Participant Link
* Raw Score or Points - The non-normalized points that were awarded to the pilot in the round. This can be a computed data point based on the configuration and the raw data recorded based on the soaring discipline.
* Normalized Score or Score - This can be a computed data point. It is calculated based on the other raw scores for pilots in the group.
* Cumulative Penalty - A required integer raw value entered for every soaring discipline. It represents a penalty incurred by the pilot during the flight and is deducted from the pilot's total contest score at the contest calculation stage. It is distinct from discipline-specific penalties and from any penalty applied by the contest director.
* Penalty - A raw point penalty.
* Penalty Not Discarded - An indicator that the penalty is applied to the pilots final score. If the flight is discarded due to the "dropped round" configuration for the contest and this is set the penalty applied in this round will still apply to the pilots overall score.
* Pilot Retired - The pilot has retired in this round or an earlier round and their score is zero for the round. This is separated from the "Zero Score" to show that the pilot is no longer competing in the contest.
* Zero Score - Indicates that the score should be calculated as zero. This is an indicator in the case that the pilot could not enter a score for this round. An example situation would be that the pilot forgot to fly that round. This shows that the values for the scoring points are actually computed as 0 and not that the pilot has yet to enter a score.

The group score entity will need to accommodate the different data points needed to be collected for various soaring disciplines. In addition the need to track the originally entered score and official score will be needed.

## Review Request

This entity represents a review request for a previously recorded score.

* Group Score Link
* Status
* Score data
* Participant Link - This is set if the requestor is not the pilot. This happens when teams are used and another participant on the team requests the review.
