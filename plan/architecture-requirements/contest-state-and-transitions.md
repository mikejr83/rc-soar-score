# # RC Soar Score Architecture - Contest State and Transitions

A contest is both a conceptual and entity data point. The contest phases document describes the logical steps in contest's life. This document breaks those down to more technically aligned states.

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

## Locked State

A contest in the running state can be moved into the locked state. This indicates that no new scores can be entered through the self-scoring screens. The contest director or officials may enter scores.

The contest director may "unlock" the contest to return it back to the running state.

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

Contest directors storing their data as a backup on the remote site may wish to archive contests. This is done to prevent them from showing in their list of contests in the UI when they're requesting a contest to open for reference or when copying from an old contests. Contest directors may run many contests and having old contests that are not needing administration can be archived from view. These contests are not deleted. Any published data from the contest still remains public and searchable.

A contest in the completed state can be archived.

Once the contest enters the archived state it can be transitioned back to completed.

### Delisted

Once a contest has been published and is public it can be made private by the contest director. This is generally done to hide the overall results before an awards ceremony. This does not indicate that the contest is delisted.

Delisting occurs when the contest director wishes to retract a published contest. The contest director will find a contest that they have published previously and was **not** made public. They indicate that they wish to delist it. This disables the contest from any self-scoring functionality. This is intended to retract a contest that may have been published in error and prevent scores from being entered.

## Deleted

A contest director can delete data on their local instance of the application. Deleting a contest removes it and its associated data from the contest director's instance. They will be notified that upon sync with the remote system it will be deleted in their remote data.

Contests that have been published and made public at least once cannot be immediately deleted. These contest move to a "Pending Delete" state.

## Pending Delete State

This state is for contests that a contest director has deleted but were once publicly published. It will receive the same type of treatment as a delisted contest, no scoring can be entered. It is removed from the contest director's local data. It is marked as pending delete in their remote data. Additionally, it is hidden from the public site.

The data necessary for it to be retained in its public published form will not be removed. A global site administrator (not covered in this documentation) can view these and approve their removal. If the administrator deems the delete is taking place in good faith all the public data and the contest director's remote data for the contest is removed. However, if the administrator believes that the delete was made in error or maliciously the administrator may restore the data.

The contest moves to the restored state.

This state is tracked so that a contest director cannot inadvertently or maliciously delete previous contests from the public record without some administrative approval.

## Restored State

A contest moves here when a site administrator deems that a contest in the pending delete state is mistakenly or maliciously deleted. The contest director's remote data is modified such that the contest appears the same as a contest in the archived state. It additionally gaines the attribute of restored.

The contest is made public on the site again.

At this point only an administrator may go back and fully delete the contest.

## Contest Attributes

The following are not "states" for the contest but attributes which are given to contests throughout their life. These attributes may be applied in certain states or can deny an contest from entering another state.

### Scoring Opened

A contest having the published attribute can have a contest director open the contest to scoring. This is not required. The contest may be published and marked as public, but the contest will be scored only by the contest director or another official.

When the contest director opens scoring to participants the system will look at the participants and invite them to a special URL that enables them to enter their scores.

The system will use follow the process in [`self-scoring-invites.md`](./self-scoring-invites.md) to determine how to send the invites to participants.

### Published

A contest director may chose to publish the contest at any point after the matrix has been created. The act of publishing the contest prepares the contest for public consumption and the ability for participants to add scoring data. A contest does not have to be published for the application to track its data.

A contest must be published to:

* Enable pilots or participants to enter scores online.
* For the contest to be marked as public and it to be found via searching on the public site.
* Users to see their past performance related to contests they may have participated in.

Publishing a contest does not immediately open scoring. It is the first step to enabling that functionality.

After publishing the contest director can open online scoring.

### Public Contest

A contest director may mark a contest as public or private. This is only applicable to published contests. A published contest that has been marked private enables the contest to be self-scored by pilots and participants but not visible on the public site. A published contest may be marked as public so that it can be found on the public web site and viewed but have scoring locked so that only officials may enter scores.