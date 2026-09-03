# RC Soar Score Architecture - Entities/Data

These are the conceptual data requirements for the system. Unique identifiers for the resulting entities are necessary but not explicitly shown here.

There are two locations where data is stored, in the main API layer and locally within the PWA application. This places data in 3 states:

* Local data
* Data sent to the API layer for storage as a back-up measure.
* Published data

Local data is what contest directors generate using the PWA. When the user is using the web site it is assumed that the data will be automatically stored in the greater system linked to their account. When the contest director is using the offline application it is assumed that the data is stored primarily locally and is then synced to the API

## Users

Users are accounts which have been created to track data in the system. These will contain the basic information about someone that is using the system. This is used to defined ownership over other entities.

* First and last name
* Email address
* Identity Provider identifier

## Contest

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
* Role name - The name of the role the user is assuming for the contest.
* Role type - Indicates the link as a pilot or non-flier.
* Unique identifier - Used when a unique identifier number is selected for participants in the contest.

## Participant Model Link

If the contest is configured to track models per pilot then each model is linked to the contest though the participant link. This enables the participant to have different models at different contests.

* Model name
* Manufacturer
* Contest Model Identifier

## Participant User Link

A participant may be linked to a user account. When a user account that is created a check is run against the participant entities. If no participant entity with that email exists a participant entity is created and a link created between the participant and the user account. If the search finds a participant that exists with the same email then only the link between the user account and the participant is created.

This is kept as a link instead of a foreign relation because future development may see a user account being related to multiple participants. This would be indicative of a situation where emails changed or a new user account had to be created.
