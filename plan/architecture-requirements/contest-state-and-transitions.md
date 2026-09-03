# # RC Soar Score Architecture - Contest State and Transitions

A contest is both a conceptual and entity data point. The contest phases document describes the logical steps in contest's life. This document breaks those down to more technically aligned states.

## Created State

A contest is in the initial state of created after a contest director provides the basic properties: name, dates, and host location. A contest director could close the app, reopen it, and see the contest in their list of contests. They could select it and continue with it.

### Transitioning To Configuration

A contest will stay in the created state until the contest director starts modifying the configuration. Modifying the configuration starts with selecting a class/discipline for the contest. Once this is selected the contest is moved into the configuration state.

## Configuration State

A contest requires configuration to be completed. The configuration state starts when the contest director selects a class/discipline for the contest. After the contest director acknowledges that their selection for the discipline the contest becomes configurable and the class/discipline is locked.

The contest director then performs all the configuration necessary for the contest.

The contest director will need to provide:

* Participants and their options
* Scoring options
* Scoring rules for the discipline
* Draw options

### Draw or Matrix Creation

The last thing that is performed in the configuration state is the drawing of pilots for assignment into groups within rounds. This is the creation of the flight matrix. Once a valid matrix has been created the contest moves to the "ready" state.

Draws can be performed multiple times. Additional rounds can be added to the flight matrix.

### Exiting the Configuration State

Configuration is considered complete once all the required configuration is provided and a valid flight matrix has been created. At this point the contest could have scores entered. It enters the "ready" state.

An important note is that configuration can be revisited at later points during the contest.

## Ready State

This state occurs after the contest is configured and the draw is performed but before scores have been entered.

## Running State

Once a score is entered the contest enters the running state.
