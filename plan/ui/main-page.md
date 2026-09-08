# RC Soar Score User Interface - Main Page

The user comes to the main page after they have logged in or if they have selected offline mode in the offline application.

This document will use the term button to indicate a UI element which the user will interact with to perform an action. This typically will be a navigation action. The use of popups and modals are to be minimized.

This page is to show the following:

* Recently created contests.
* A button to show all contests.
* A button for creating new contests.
* A button to delete or delist a selected contest.
* A button to edit previous participants.
* A button to manage participant roles for the system.
* A button to manage landing bonus tables.

## Recently Created Contests

A list of the most recent contests should be presented on this page. This is done so that a contest director can quickly open the last contest if it is to be continued. This list should contain the last 10 contests. If the user has more than 10 contests a button to show all contests should be available/enabled. When clicking this the next 50 contests are loaded.

The list should show the name of the contest, the contest dates, and the venue or location. A column should be reserved for the status of the contest. The column should indicate if the contest has been published, its current state, its public site visibility, and its scoring visibility. If a contest is pending a delisting on the public site it should also be indicated.

## Creating a New Contest

To create a new contest the contest director clicks on the button for creating a new contest. They are navigated to the wizard for creating the contest.

## Deleting or Delisting a Selected Contest

A contest director will be able to delete a contest when it is selected in the list. The button to do so should only be enabled when a contest is selected.

Contests can be deleted only in certain situations. If the contest does not meet those requirements then an alert dialog should be presented to the user with the reason why it cannot be deleted. The user should confirm the deletion before it takes place. The acknowledgement should indicate that deleted contests will be removed from the user's back up data.

The UI should indicate if a contest is to be delisted from the public site. It should do this through a modal dialog. THe dialog should present what delisting means and how it is performed. The user will need to acknowledge that they wish the contest to be removed from the public site.

## Managing Previous Participants

The application should present a button to navigate to a participant management screen.

## Managing Participant Roles

The application should present a button to navigate to a screen to manage the participant roles.

## Landing Bonuses

The application should present a button to navigate to a screen for managing landing bonuses.
