# Minimally Viable Product Plan

The application consists of the following parts:

* Angular application for contest management - Online web application where users can enter scores.
* The same angular application wrapped in a desktop app
* Backend API
* Public site for viewing contests and their scores.

The MVP to be achieved is the offline version of the application. This will be referred to in the rest of the document as the desktop application.

The desktop application does not require the contest director to create an account. However, since it is reusing the code from the website consideration should be given to all implementation where the client application is accessing the API layer for authn/authz. In the initial implementation it is understood that the authn/authz will not be present.

The UI should be designed in accordance with Material 3 standards.

The page layouts should be designed around screen sizes no smaller than a tablet for all administrative screens. The score entry pages for participants should be built in a mobile-first design consideration.

The following will describes the pages and UI elements for the application. The descriptions should be applicable to both the web site and desktop versions. Any deviations will be noted.

## Application UI Frame

The application will have some global components that will wrap the application experience.

Online application: None at this time

Offline application:

* Logged in status
* Network and API status

## Initial Page

The application should have a landing screen. The page will describe the application.

It will have buttons to create an account or to log in. This is applicable to both the site and desktop versions. However for MVP it will not be included.

For the desktop application:

* A navigation element will indicate interacting with it will go to the offline mode of the application.

## Contest Selection Page

The user enters this page after they have logged in or clicked the offline mode button on the intial page.

This page will show the user the last five contests that were opened. There will be a button to show all contests. A button for creating a new contest is available. Selecting a contest in the list should enable a delete button to be used. A button to open the selected contest or double clicking on the contest will open it.

The page should also have navigation elements to go to management screens for system data.

For the desktop application:

* A button should enable the syncing of data if the user is logged in and there is an internet connection.

## System Data Managers

There are several types of system data that can be modified by contest directors. This data is generally in a list format with several properties. A single reusable screen can be used to handle the editing of the various types of system data. Basically, there are several types of the system data. Selecting one of the types brings up the collection of data within it. The collection of data within it can be added or removed. The various values can be modified.

## New Contest Wizard

On the contest selection page the user can click a button to create a new contest. This will navigate to the contest creation wizard. This wizard presents the information to the user in an easy step-by-step process to create and configure a new contest.

1. The first step in the wizard will gather the basic contest details, the name, dates, venue, etc.
  a. The user is asked if they wish to copy from an existing contest.
  b. The user can select a previous contest from either local data or if connected to the internet search for public contests.
  c. Copying from a contest can include just configuration or also include pilots.
  d. If including pilots an option to select the top x number of pilots given.
2. The contest discipline is selected. This is skipped if a previous contest was copied.
3. Participant options are presented. This is not skipped if a previous contest was copied but a notice that the values were prefilled from the previous contest should be displayed.
4. Participant selection - This is not skipped if a previous contest was copied but a notice that the participants were selected based on what was indicated on the first step of the wizard.
5. Scoring options - These should default to the values from the copied contest.
6. Scoring rules - These should default to the values from the copied contest.
7. Drawing the flight matrix.

Once the wizard is completed the user is taking the contest configuration page.

## Contest Configuration Page

On the contest selection page there user can select an existing contest. They are then taken to the this page.

The contest configuration page shows all of the configuration elements that were selected during the contest creation wizard. It enables the contest director to adjust any configuration values which can be done based on the state of the contest.

The page should have navigation elements to head to various tasks that are completed when administering the contest:

* Scoring
* Reports
* Visibility

Action buttons for the following operations may also show depending on the state of the contest:

* Lock contest

## Scoring

The scoring pages used by a contest director are different from the individual score entry pages participants will use when submitting self-scores. The score pages will present a complete group of pilots at a time in a grid fashion.

A main navigation element is present on the page. This takes the user back to the contest configuration page.

The page functions in two level: The outer navigation level is selecting the round to view. The inner navigation is selecting the group to view. The page should track the currently selected round and group. This is done for the navigation elements and to determine what data to show.

The round navigation:

* Go to the current round (the latest round with a score in a group)
* Go to the first round
* Go to the last round (in the contest)
* Go forward a round
* Go back a round.

Sub-navigation will mimic the round navigation:

* Go to the first group
* Go to the last group
* Go to the next group
* Go to the previous group

The main component on the scoring page is a grid of pilots.

This grid should contain the following columns:

* Pilot number (if enabled)
* Team (if enabled)
* Pilot name
* The scoring details for the discipline
* Raw points
* Group points
* Penalty
* Score Submitted from Participant - The row should indicate that the score was entered by a participant and not the contest director.
* Review Requested (if enabled and a review is requested)

The grid should enable the user to select the scoring details to be entered and update them. The interaction with the UI by the user should be follow these requirements:

* Times are entered without the need to enter a ":". Typing 630 by the user will enter 6:30, or 6 minutes and 30 seconds.
* Times with a decimal are entered without the ":". Typing 630.4 by the user will enter 6:30.4.
* The user's UI locale should dictate the need for a comma or period for decimals.

The UI should let the user lock the scores for the group or the round. Individual rows, may be selected and marked as "Official".

A button should appear with a label of "Score Check". This runs the score check and displays a popup of any scores that are missing.

## Basic API Layer

The offline web application will need to rely on an application server that does not require a large amount of dependencies to be installed. The offline application will be wrapped by Electron. Therefore it is likely a NodeJS application server should be used. This will enable a version or portion of the application layer running as the remote API could be utilized for handling the requests from the wrapped application locally.
