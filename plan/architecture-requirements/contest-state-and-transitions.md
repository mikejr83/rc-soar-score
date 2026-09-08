# RC Soar Score Architecture - Contest State and Transitions

A contest is both a conceptual and entity data point. The contest phases document describes the logical steps in contest's life. This defines the lifecycle states of a contest in a technically competent manner.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Created|Contest exists but is not yet configured|Director creates the contest with minimum properties: name, dates, host, location|Created → Configuring when discipline or first configuration action begins|
|Configuring|Contest is being set up|Discipline selected or configuration begins|Configuring → Ready after required configuration and valid draw are complete|
|Ready|Contest is configured and draw exists, but scoring has not started|Valid flight matrix exists|Ready → Running when first score is entered|
|Running|Scores are in progress|At least one official or participant-submitted score exists|Running → Completed when contest is ended|
|Completed|Contest is finished|Director marks complete, or completion conditions are met|Completed → Published or Archived|
|Archived|Public historical record, no more edits|Completion is met and is made public|Published → Pending Delete|
|Pending Delete|Contest director is requesting the removal of one of their contests which is published|Contest director makes the request|Pending Delete → Restored or Deleted|
|Restored|Contest is restored by an administrator.|Administrator denies the delete request|terminal|
|Deleted|Contest is removed from the public site|Administrator approves the delete request|terminal|

## Created State

A contest is in the initial state of created after a contest director provides the basic properties: name, dates, and host location. A contest director could close the app, reopen it, and see the contest in their list of contests. They could select it and continue with it.

### Transitioning To Configuration

A contest will stay in the created state until the contest director starts modifying the configuration. Modifying the configuration starts with selecting a class/discipline for the contest. Once this is selected the contest is moved into the configuration state.

## Configuration State

A contest requires configuration to be completed. The configuration state starts when the contest director selects a class/discipline for the contest. After the contest director acknowledges that their selection for the discipline the contest becomes configurable and the class/discipline cannot be changed.

The contest director then performs all the configuration necessary for the contest.

The contest director will need to provide:

* Participants and their options
* Scoring options
* Scoring rules for the discipline
* Draw options

The configuration state cannot be revisited once a contest enters the running state. This doesn't mean that specific parameters cannot change. It just means that certain considerations may need to be made.

### Draw or Matrix Creation

The last thing that is performed in the configuration state is the drawing of pilots for assignment into groups within rounds. This is the creation of the flight matrix. Once a valid matrix has been created the contest moves to the "ready" state.

Draws can be performed multiple times. Additional rounds can be added to the flight matrix.

If the contest has specified lane assignments they are assigned to the pilots in each group during the draw. These assignments are random. A lane number is a number starting from 1 to the maximum number of pilots that may be in the group.

Once a draw has been performed the following cannot be changed:

* Use teams
* Use roles
* Draw mode
* Groups per round

After the matrix is computed the following can be changed regarding lane assignments.

* Removal of lane assignment
* Reassign lanes - The matrix remains unchanged but the lane assignment for each pilot in the group is randomly selected.

### Exiting the Configuration State

Configuration is considered complete once all the required configuration is provided such that a valid flight matrix has been created. At this point the contest could have scores entered. The contest is ready to begin, but technically configuration could change, the contest director may redraw the matrix, add or remove rounds, etc.

## Running State

Once a score is entered the contest enters the running state.

At this point it becomes critical that any scores which are entered are maintained. The contest director may notice a major error and need to revisit the contest configuration but certain aspects will cause the scores to be discarded or a redraw of the flight matrix to occur.

Once the first score has been entered the following configuration options are no longer adjustable:

* Use teams
* Use roles
* Specified scoring rules for each discipline. These are defined in the discipline documentation.

The following can be changed during the running state but only affect groups with no scores:

* Lane assignment - Assignment can be removed or can be redrawn for the remaining groups and rounds.

The following can be changed at any point scores have been entered. These changes reflect how the round score is computed for a pilot and does not affect how the raw score data was recorded. Hence, they can be changed at any time.

* Group Score
* Total score: Rounded or Truncated
* Total score: number of decimals
* When the dropped round score takes effect.

## Paused State

*Does not apply to contests which are only stored offline.*

A contest in the running state can be moved into a paused state. This indicates that no new scores can be entered through the self-scoring screens. The contest director or officials may enter scores.

This can be used for a number of reasons. Often, contest directors will put self-service entry of scores into a paused state during a break in the contest while they are performing an overall validation of the contest. The contest director may be updating scores via paper backups but does not wish participants to enter any other scores.

The contest director may "unpause" the contest to return it back to the running state.

## Locked State

A contest in the running state can be moved into the locked state. This indicates that scores cannot be modified, no new rounds may be added, and participation may not change.

This is often done by contest directors to prevent any accidental changes when a contest is paused. An example would be a contest director locking a contest after the completion of competition for the day and then unlocking it at the start of the next day.

The contest directory may "unlock" the contest to return it back to the running state.

## Completed State

The concrete ways that the contest has moved to the completed state are:

* If all the groups for all the rounds in the matrix have a score (or indication that a zero score is recorded) for each pilot that has not retired.
* No score has been entered in after some time period (generally there is not more than a one day gap for weather days).
* The contest director has marked the contest as completed.

Other ways to determine if the contest has completed:

An assumption can be made that the contest is completed with the following conditions:

* All rounds where any pilot has a score also has a score for all other pilots
* All rounds where any pilot has a score are only missing scores for pilots that have retired.

It is only an assumption because the contest director may be instructing the pilots to actively complete their scoring before the next round starts. Thus, if the assumption was made in round 7 of a 9 round contest, the contest may not be over, but the contest director is making sure that everyone is aware of their placing before entering the last two rounds.

## Archived State

### Contests Stored Only Locally

A contest that is stored only on the local offline instance of the application can be archived. This can happen at any point. It is intended to hide the contest from any local selection but not remove the data. An archive contest can return to its prior state through the contest director action.

### Contests Stored Remotely

A contest that is completed and has been marked as public enters this state. The transition from completed to archived may be immediate as contests may be on the remote site and marked public during the running state. Thus, once the contest is marked as completed it transitions to the completed state and then immediately to the archived state.

This state defines a contest that is now being shown on the public site for historical purposes. It is no longer editable.

## Deleted

It may become necessary that a contest director needs to delete a contest. It could be that the contest was a test or that it was created in error.

### Contests Stored Locally

For contests that were created and stored exclusively locally, a contest director can delete the data. After confirmation the contest is removed and there is no further actions.

### Contest Stored Remotely

A contest director may wish to delete a contest that they created and is also synced to the the remote site. Deleting a contest removes it and its associated data from their local data after an acknowledgement. If the delete was performed offline they will be notified that on the next sync it will be removed in their remote data. When the sync occurs the contest director will be notified that contests will be delete on the remote site and that they may cancel and restore their local data.

If the contest has been made public at least once cannot be immediately deleted. These contest move to a "Pending Delete" state.

## Pending Delete State

This state is for contests that a contest director has deleted but were once publicly visible. It will receive the same type of treatment as a delisted contest, no scoring can be entered. It is removed from the contest director's local data. It is marked as pending delete in their remote data. Additionally, it is hidden from the public site.

The data necessary for it to be retained in its public published form will not be removed. A global site administrator (not covered in this documentation) can view these and approve their removal. If the administrator deems the delete is taking place in good faith all the public data and the contest director's remote data for the contest is removed. However, if the administrator believes that the delete was made in error or maliciously the administrator may restore the data.

The contest moves to the restored state.

This state is tracked so that a contest director cannot inadvertently or maliciously delete previous contests from the public record without some administrative approval.

## Restored State

A contest moves here when a site administrator deems that a contest in the pending delete state is mistakenly or maliciously deleted. The contest director's remote data is modified such that the contest appears the same as a contest in the archived state. It additionally gaines the attribute of restored.

The contest is made public on the site again.

At this point only an administrator may go back and fully delete the contest.