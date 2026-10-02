# RC Soar Score System Management Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Management of the contest is included a web application used in online access. The application is also wrapped in a desktop shell for use when there is no internet or as desired by the contest director.

The management application will need to manage various system data for a contest director.

A contest director will need to:

- Open existing contests to either review previous contests.
- Create new contests
- Delete contests
- Export contest data
- Maintain a list of pilots that have participated in the contests by that contest director (frequent participants) *would also be considered managing the local data stored for pilots)
- Configuring of various global configuration
  - Landing bonuses
  - Participant types

## Opening Contests

Contests will be linked to a contest director. These may be stored locally if the application is used in an offline scenario. A contest director may wish to continue a contest that was previously created or review a past contest.

## Creating New Contests

Creating new contests is a primary function. The application will take a name for the contest, a range of dates when the contest is occurring, and where the contest is located. This information is stored for both display and filtering in the system.

When creating a new contest a previous contest may be selected. The contest director can select the previous contest do a number of tasks when the new contest is created:

- Copy the configuration along with the class and discipline
- Copy the pilots
- Copy the configuration, class/discipline, and a sub-set of pilots for a "fly-off" scenario.

## Deleting Contests

Contests may be created in error or it may be desired by the contest director to remove a contest. Contests created locally can be removed after a warning and acknowledgement by the user. Contests that were pushed to the public site cannot be deleted. A request can be sent for it to be delisted.

## Managing Participants

Pilots, helpers, and team managers are all participants that will be tracked in contests. Most contest will only include pilots that are participating and receiving scores. However, large complex contests may feature helpers and team managers. These are tracked for informational purposes only as "non-flyer" participant types.

This information is stored as information linked to the contest director. A default set of participant types will be provided to all contest directors. They may add their own, but those types are not shared.

Participants linked to a contest director can be managed "globally". That is, any of the participants that have participated in a contest by the contest director can have data edited by that contest director. Those edits remain the contest directors. A contest director can retrieve the latest information about a participant from the remote, public site. This is only provided if the pilot volunteers the data on registration.

### Common Participant Data

The following data points is considered participant data for any contest.

- First and Last Name
- Club
- FAI Number
- National Organization ID
- City
- State
- Country
- Email - Always private

First and last name and email are required. All of the other fields are optional. The email address is used when determining if the participant in a contest directors data matches one that has already been created in the remote system.

### Privacy and Data Syncing

The system will not require participants to register and maintain a user account. The FAI Number, National Organization ID, city, state, and country can be tracked by the contest director. The contest director may enter just the required or all the available data. When the contest is published for public viewing along the first and last name and the country of the participant will be shown.

When the system is syncing data to the remote site it is still within the contest director's data. It is not shared with any other contest director. However, if a participant creates a user account and wishes to allow their data to be shared their participant record will become open for all contest directors to utilize. All the participant data will become read-only from the contest director's point of view. The user will have the ability to hide or show their email to the contest director. If the user has decided to hide their email the contest director will show that it is available to the system.

### Contest Specific Participant Data

The contest director may add additional information about the participant when they are added to a contest.

- Class
- Role

The "Class" is an optional value provided by the contest director when adding a participant as a pilot to a contest. It is only necessary when the contest director indicates that classes are being used. The last Class value used for a pilot will be used but the contest director has the ability to change it when adding to the contest.

The role is only needed when the contest director selects the option for "roles" after teams are selected.

### Roles

The application will track more than just pilots participating in the contest. This is done so that the application can present a full picture of all the individuals participating at large complex events when teams are involved. The application will track a "role" that can be assigned to a participant when they are added to the contest. Roles are arbitrary but they are divided into two groups/types, pilots and non-flyers. Pilots receive scores. Non-flyer participants are not shown on score entry and score reports screens but are shown when team information is displayed in reports.

At the system configuration level the contest director should see these roles. They should be able to add, delete, and modify them. The contest director cannot delete or modify the default "Pilot" role. There also cannot be more than one "pilot" type. The contest director can only add non-flyer types.

Default participant roles:

- Pilot - A pilot type and the default for all participants added to a contest.
- Helper - A non-flyer
- Team Manager - A non-flyer.

## Landing Bonuses

Landings are a component of certain contest disciplines. Depending on the region where a contest is held and for the discipline what is entered by an official or pilot may be different than the points awarded. The application will store different types of landing bonuses that are selectable by the contest director when configuring the contest. The bonuses are essentially key/value pairs. The user entering the score will enter the key and the value are the points awarded.

The data for the landing bonus is tracked as a name for the landing bonus type, "F3J Distance", "F5J Points", etc. The a value for the key can be provided for use in screens requesting the data. The value is always known as "Points".

This information is stored as information linked to the contest director. A default set of landing bonuses are provided. Contest directors may add their own. They are only visible to the contest director which added them.
